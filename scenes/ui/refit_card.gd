class_name RefitCard
extends Button
## One refit card (icon, designation, level/hardpoint, blurb, nose-swap note), shared by the
## Field Refit screen and the Armory. Built in code so both screens stay in step.

const HARDPOINT_KEYS: Dictionary[int, String] = {
	WeaponData.Hardpoint.NOSE: "HARDPOINT_NOSE",
	WeaponData.Hardpoint.WING_PYLONS: "HARDPOINT_WING_PYLONS",
	WeaponData.Hardpoint.ENGINE: "HARDPOINT_ENGINE",
	WeaponData.Hardpoint.HULL: "HARDPOINT_HULL",
	WeaponData.Hardpoint.SALVAGE_MOUNT: "HARDPOINT_SALVAGE_MOUNT",
}
const AMBER: Color = Color(1.0, 0.7, 0.2)
const CYAN: Color = Color(0.35, 0.85, 1.0)
const PALE: Color = Color(0.85, 0.85, 0.8)
const SWAP_RED: Color = Color(1.0, 0.45, 0.35)
## Menu navigation: which focus neighbour each move action goes to.
const MENU_SIDES: Dictionary[String, int] = {
	"move_up": SIDE_TOP, "move_down": SIDE_BOTTOM, "move_left": SIDE_LEFT, "move_right": SIDE_RIGHT,
}

## Gamepad stick / trigger directions currently past their deadzone (action -> held).
static var _stick_held: Dictionary[String, bool] = {}

var refit: RefitData

var _row: HBoxContainer
var _swap: Label


## `in_variant_group`: the card sits under a "CHOOSE A VARIANT" header that already names the level.
func _init(card_refit: RefitData, height: float = 98.0, in_variant_group: bool = false) -> void:
	refit = card_refit
	custom_minimum_size = Vector2(0.0, height)
	mouse_entered.connect(grab_focus)
	_row = HBoxContainer.new()
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	_row.add_theme_constant_override("separation", 12)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	var icon: WeaponIcon = WeaponIcon.new()
	icon.custom_minimum_size = Vector2(44.0, 44.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.weapon = refit.weapon
	icon.field_mod = refit as FieldModData
	icon.system = refit as SystemRefitData
	_row.add_child(icon)
	var lines: VBoxContainer = VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override("separation", 1)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(lines)
	lines.add_child(make_label(tr(refit.display_name()), 16, AMBER))
	lines.add_child(make_label(info_text(refit, in_variant_group), 12, CYAN))
	var desc: Label = make_label(tr(refit.desc_key), 12, PALE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(desc)
	_swap = make_label("", 12, SWAP_RED)
	lines.add_child(_swap)
	refresh_swap()


## Adds a fixed-width column on the right (the Armory's price tag).
func add_side(control: Control) -> void:
	_row.add_child(control)


## The nose-swap note depends on what's mounted now, so the Armory refreshes it after each buy.
func refresh_swap() -> void:
	var swapped: WeaponData = refit.swaps_out()
	_swap.visible = swapped != null
	if swapped != null:
		_swap.text = tr("REFIT_SWAP") % tr(swapped.name_key)


static func info_text(card_refit: RefitData, in_variant_group: bool = false) -> String:
	if card_refit is FieldModData:
		return TranslationServer.translate("REFIT_FIELD_MOD")
	var level: String = TranslationServer.translate("REFIT_LEVEL") % card_refit.level
	if card_refit.variant != "" and in_variant_group:
		level = TranslationServer.translate("REFIT_VARIANT") % card_refit.variant
	elif card_refit.variant != "":
		level = TranslationServer.translate("REFIT_LEVEL_VARIANT") % [card_refit.level, card_refit.variant]
	return "%s  ·  %s" % [level, TranslationServer.translate(HARDPOINT_KEYS[card_refit.hardpoint])]


static func make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Arrow keys/WASD move focus and Fire/J presses the focused button, on any menu screen.
## Returns true if it used the event.
static func handle_menu_input(event: InputEvent, viewport: Viewport) -> bool:
	var focused: Control = viewport.gui_get_focus_owner()
	if focused == null:
		return false
	var side: int = -1
	for action: String in MENU_SIDES:
		# Every action is checked (no early exit) so the stick's held state stays up to date.
		if _menu_pressed(event, action) and side == -1:
			side = MENU_SIDES[action]
	if side != -1:
		var next: Control = focused.find_valid_focus_neighbor(side)
		if next != null:
			next.grab_focus()
		viewport.set_input_as_handled()
		return true
	if _menu_pressed(event, "fire") and focused is Button:
		(focused as Button).pressed.emit()
		viewport.set_input_as_handled()
		return true
	return false


## A key or button press, or the moment a stick / trigger is pushed past its deadzone. A held stick
## sends a stream of motion events, and each would otherwise count as a new press and skip cards.
static func _menu_pressed(event: InputEvent, action: String) -> bool:
	if not event is InputEventJoypadMotion:
		return event.is_action_pressed(action)
	if not event.is_action(action) and not _stick_held.has(action):
		return false
	var now: bool = Input.is_action_pressed(action)
	# Unknown counts as held: a stick or trigger still held from the fight must be let go first.
	var was: bool = _stick_held.get(action, true)
	_stick_held[action] = now
	return now and not was
