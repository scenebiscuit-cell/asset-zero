class_name FieldRefitScreen
extends CanvasLayer
## Field Refit loadout screen (DESIGN.md §7.1): after SECTOR CLEAR, pick 1 of 3 random refits.
## A ship schematic (both forms) highlights the hardpoint of the offer in focus. One reroll per
## screen, paid in salvage; the price rises with every reroll bought this run.
## Pauses the game while open (process_mode ALWAYS in the scene).

signal finished

const HARDPOINT_KEYS: Dictionary[int, String] = RefitCard.HARDPOINT_KEYS
const AMBER: Color = RefitCard.AMBER
const AMBER_DIM: Color = Color(1.0, 0.7, 0.2, 0.45)
const CYAN: Color = RefitCard.CYAN
const PALE: Color = RefitCard.PALE

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
	if visible and _accepting:
		RefitCard.handle_menu_input(event, get_viewport())


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
		var card: Button = _make_card(offer[0] as RefitData, false)
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
		var card: Button = _make_card(refit, true)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(card)
		if first == null:
			first = card
	return first


func _make_card(refit: RefitData, in_variant_group: bool) -> Button:
	var card: RefitCard = RefitCard.new(refit, 98.0, in_variant_group)
	card.focus_entered.connect(_highlight.bind(refit.hardpoint))
	card.pressed.connect(_choose.bind(refit))
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	return RefitCard.make_label(text, font_size, color)


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
		var system: SystemRefitData = GameState.system_refit(
				RefitData.Line.PROPULSION if hardpoint == WeaponData.Hardpoint.ENGINE else RefitData.Line.ARMOR)
		if weapon != null:
			fitted.text = tr(weapon.name_key)
		elif system != null and hardpoint in [WeaponData.Hardpoint.ENGINE, WeaponData.Hardpoint.HULL]:
			fitted.text = tr(system.display_name())
		elif hardpoint == WeaponData.Hardpoint.ENGINE:
			fitted.text = tr("LOADOUT_STOCK_ENGINE")
		elif hardpoint == WeaponData.Hardpoint.HULL:
			fitted.text = tr("LOADOUT_BARE_FRAME")
		else:
			fitted.text = tr("LOADOUT_EMPTY")
