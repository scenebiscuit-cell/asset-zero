class_name FieldRefitScreen
extends CanvasLayer
## Field Refit loadout screen (DESIGN.md §7.1): after SECTOR CLEAR, pick 1 of 3 random refits.
## A ship schematic (both forms) highlights the hardpoint of the offer in focus. One reroll per
## screen, paid in salvage; the price rises with every reroll bought this run.
## Pauses the game while open (process_mode ALWAYS in the scene).

signal finished

const HARDPOINT_KEYS: Dictionary[int, String] = {
	WeaponData.Hardpoint.NOSE: "HARDPOINT_NOSE",
	WeaponData.Hardpoint.WING_PYLONS: "HARDPOINT_WING_PYLONS",
	WeaponData.Hardpoint.ENGINE: "HARDPOINT_ENGINE",
	WeaponData.Hardpoint.HULL: "HARDPOINT_HULL",
	WeaponData.Hardpoint.SALVAGE_MOUNT: "HARDPOINT_SALVAGE_MOUNT",
}
const AMBER: Color = Color(1.0, 0.7, 0.2)
const AMBER_DIM: Color = Color(1.0, 0.7, 0.2, 0.45)
const CYAN: Color = Color(0.35, 0.85, 1.0)
const PALE: Color = Color(0.85, 0.85, 0.8)
const SWAP_RED: Color = Color(1.0, 0.45, 0.35)

@export var catalog: RefitCatalog
@export var offer_count: int = 3
@export var rerolls_per_screen: int = 1
@export var reroll_base_cost: int = 15
@export var reroll_cost_step: int = 10
## Ignores input for a moment, so a held Fire key from the fight can't pick a card by accident.
@export var input_delay: float = 0.5
## How long "INSTALLED" shows before moving on.
@export var installed_hold: float = 1.0

var _offers: Array[Array] = []
var _rerolls_left: int = 0
var _accepting: bool = false
var _loadout_rows: Dictionary[int, Array] = {}

@onready var _subtitle: Label = $Root/Subtitle
@onready var _schematic: ShipSchematic = $Root/Schematic
@onready var _loadout: VBoxContainer = $Root/Loadout
@onready var _cards: VBoxContainer = $Root/Cards
@onready var _reroll: Button = $Root/Reroll
@onready var _salvage: Label = $Root/Salvage
@onready var _installed: Label = $Root/Installed


func _ready() -> void:
	visible = false
	_reroll.pressed.connect(_on_reroll_pressed)
	_reroll.focus_entered.connect(_highlight.bind(-1))
	_reroll.mouse_entered.connect(_reroll.grab_focus)
	for hardpoint: int in HARDPOINT_KEYS:
		var row: HBoxContainer = HBoxContainer.new()
		var slot: Label = _label(tr(HARDPOINT_KEYS[hardpoint]), 12, AMBER_DIM)
		slot.custom_minimum_size.x = 150.0
		var fitted: Label = _label("", 12, PALE)
		row.add_child(slot)
		row.add_child(fitted)
		_loadout.add_child(row)
		_loadout_rows[hardpoint] = [slot, fitted]


func open(sector_number: int) -> void:
	visible = true
	get_tree().paused = true
	_rerolls_left = rerolls_per_screen
	_subtitle.text = tr("REFIT_SUBTITLE") % sector_number
	_installed.visible = false
	_refresh_loadout()
	_roll()
	_accepting = false
	await get_tree().create_timer(input_delay).timeout
	_accepting = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _accepting:
		return
	# WASD and J work here too, not just the arrow keys and Enter/Space.
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	var side: int = -1
	if event.is_action_pressed("move_up"):
		side = SIDE_TOP
	elif event.is_action_pressed("move_down"):
		side = SIDE_BOTTOM
	elif event.is_action_pressed("move_left"):
		side = SIDE_LEFT
	elif event.is_action_pressed("move_right"):
		side = SIDE_RIGHT
	if side != -1:
		var next: Control = focused.find_valid_focus_neighbor(side)
		if next != null:
			next.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("fire") and focused is Button:
		(focused as Button).pressed.emit()
		get_viewport().set_input_as_handled()


func _roll() -> void:
	for child: Node in _cards.get_children():
		child.queue_free()
	_offers = catalog.roll_offers(offer_count)
	var first: Button = null
	for offer: Array in _offers:
		var button: Button = _add_offer(offer)
		if first == null:
			first = button
	_update_reroll()
	if first != null:
		first.grab_focus()


## Adds one card, or a header plus an A/B pair for a variant choice. Returns the first button.
func _add_offer(offer: Array) -> Button:
	if offer.size() == 1:
		var card: Button = _make_card(offer[0] as RefitData)
		_cards.add_child(card)
		return card
	var group: VBoxContainer = VBoxContainer.new()
	group.add_theme_constant_override("separation", 2)
	group.add_child(_label(tr("REFIT_VARIANT_HEADER") % (offer[0] as RefitData).level, 12, CYAN))
	var pair: HBoxContainer = HBoxContainer.new()
	pair.add_theme_constant_override("separation", 8)
	group.add_child(pair)
	_cards.add_child(group)
	var first: Button = null
	for refit: RefitData in offer:
		var card: Button = _make_card(refit)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(card)
		if first == null:
			first = card
	return first


func _make_card(refit: RefitData) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = Vector2(0.0, 98.0)
	card.focus_entered.connect(_highlight.bind(refit.hardpoint))
	card.mouse_entered.connect(card.grab_focus)
	card.pressed.connect(_choose.bind(refit))
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var icon: WeaponIcon = WeaponIcon.new()
	icon.custom_minimum_size = Vector2(44.0, 44.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.weapon = refit.weapon
	icon.field_mod = refit as FieldModData
	row.add_child(icon)
	var lines: VBoxContainer = VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.add_theme_constant_override("separation", 1)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lines)
	lines.add_child(_label(tr(refit.display_name()), 16, AMBER))
	lines.add_child(_label(_info_text(refit), 12, CYAN))
	var desc: Label = _label(tr(refit.desc_key), 12, PALE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(desc)
	var swapped: WeaponData = refit.swaps_out()
	if swapped != null:
		lines.add_child(_label(tr("REFIT_SWAP") % tr(swapped.name_key), 12, SWAP_RED))
	return card


func _info_text(refit: RefitData) -> String:
	if refit is FieldModData:
		return tr("REFIT_FIELD_MOD")
	var level: String = tr("REFIT_LEVEL") % refit.level
	if refit.variant != "":
		# The group header already says the level, so the half-width card only names the variant.
		level = tr("REFIT_VARIANT") % refit.variant
	return "%s  ·  %s" % [level, tr(HARDPOINT_KEYS[refit.hardpoint])]


func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _choose(refit: RefitData) -> void:
	if not _accepting:
		return
	_accepting = false
	GameState.install_refit(refit)
	_highlight(refit.hardpoint)
	_refresh_loadout()
	_installed.text = tr("REFIT_INSTALLED") % tr(refit.display_name())
	_installed.visible = true
	for button: Button in _all_buttons():
		button.disabled = true
	AudioManager.play("assimilate", -6.0)
	await get_tree().create_timer(installed_hold).timeout
	visible = false
	get_tree().paused = false
	finished.emit()


func _all_buttons() -> Array[Button]:
	var buttons: Array[Button] = [_reroll]
	for node: Node in _cards.find_children("*", "Button", true, false):
		buttons.append(node as Button)
	return buttons


## Pulses the hardpoint on the schematic and lights its row in the loadout list.
func _highlight(hardpoint: int) -> void:
	_schematic.highlight = hardpoint
	for row_hardpoint: int in _loadout_rows:
		var lit: bool = row_hardpoint == hardpoint
		(_loadout_rows[row_hardpoint][0] as Label).add_theme_color_override("font_color", AMBER if lit else AMBER_DIM)
		(_loadout_rows[row_hardpoint][1] as Label).add_theme_color_override("font_color", Color.WHITE if lit else PALE)


func _reroll_cost() -> int:
	return reroll_base_cost + reroll_cost_step * GameState.rerolls_bought


func _on_reroll_pressed() -> void:
	if not _accepting or _rerolls_left <= 0 or not GameState.spend_salvage(_reroll_cost()):
		return
	GameState.rerolls_bought += 1
	_rerolls_left -= 1
	_roll()


func _update_reroll() -> void:
	_salvage.text = tr("REFIT_SALVAGE") % GameState.salvage
	if _rerolls_left <= 0:
		_reroll.text = tr("REFIT_REROLL_USED")
		_reroll.disabled = true
		return
	var cost: int = _reroll_cost()
	_reroll.text = tr("REFIT_REROLL") % cost
	_reroll.disabled = GameState.salvage < cost


func _refresh_loadout() -> void:
	for hardpoint: int in _loadout_rows:
		var fitted: Label = _loadout_rows[hardpoint][1]
		var weapon: WeaponData = GameState.weapons.get(hardpoint)
		if weapon != null:
			fitted.text = tr(weapon.name_key)
		elif hardpoint == WeaponData.Hardpoint.ENGINE:
			fitted.text = tr("LOADOUT_STOCK_ENGINE")
		elif hardpoint == WeaponData.Hardpoint.HULL:
			fitted.text = tr("LOADOUT_BARE_FRAME")
		else:
			fitted.text = tr("LOADOUT_EMPTY")
