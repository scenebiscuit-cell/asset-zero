class_name ArmoryScreen
extends CanvasLayer
## Armory (DESIGN.md §7.1): a black-market dealer after the Field Refit. Sells a few items for
## salvage: the first is always a repair, the rest are rolled from the refit catalog. Each item
## can be bought once. Prices go up every sector. Pauses the game while open.

signal finished

const GREEN: Color = Color(0.45, 1.0, 0.5)
const RED: Color = Color(1.0, 0.35, 0.3)
const GREY: Color = Color(0.6, 0.6, 0.6)

@export var catalog: RefitCatalog
## Always in stock (the guaranteed repair).
@export var repair: RefitData
## Items on sale, counting the repair. R&D's "+1 Armory slot" (Milestone D) raises this.
@export var slot_count: int = 4
## Each sector after the first adds this much to every price (0.4 = +40%).
@export var price_step: float = 0.4
## Ignores input for a moment, so a held key from the last screen can't buy anything.
@export var input_delay: float = 0.4
@export var card_height: float = 112.0

var _sector_number: int = 1
var _accepting: bool = false
var _cards: Array[RefitCard] = []
var _sold: Array[bool] = []
var _price_labels: Array[Label] = []
var _state_labels: Array[Label] = []

@onready var _subtitle: Label = $Root/Subtitle
@onready var _armor: Label = $Root/Armor
@onready var _salvage: Label = $Root/Salvage
@onready var _items: VBoxContainer = $Root/Items
@onready var _message: Label = $Root/Message
@onready var _leave: Button = $Root/Leave


func _ready() -> void:
	visible = false
	_leave.pressed.connect(_on_leave_pressed)
	_leave.mouse_entered.connect(_leave.grab_focus)


func open(sector_number: int) -> void:
	_sector_number = sector_number
	visible = true
	get_tree().paused = true
	_subtitle.text = tr("ARMORY_SUBTITLE") % sector_number
	_message.text = ""
	_stock()
	_refresh()
	if not _cards.is_empty():
		_cards[0].grab_focus()
	else:
		_leave.grab_focus()
	_accepting = false
	await get_tree().create_timer(input_delay).timeout
	_accepting = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and _accepting:
		RefitCard.handle_menu_input(event, get_viewport())


## The salvage price of a refit this sector, rounded to 5.
func price_of(refit: RefitData) -> int:
	var scaled: float = refit.price * (1.0 + price_step * (_sector_number - 1))
	return int(roundf(scaled / 5.0) * 5.0)


func _stock() -> void:
	for child: Node in _items.get_children():
		child.queue_free()
	_cards.clear()
	_sold.clear()
	_price_labels.clear()
	_state_labels.clear()
	var stock: Array[RefitData] = []
	if repair != null:
		stock.append(repair)
	# Variant pairs come back as one offer; in the shop each variant is its own item.
	for offer: Array in catalog.roll_offers(slot_count - stock.size(), [repair]):
		for refit: RefitData in offer:
			if stock.size() < slot_count:
				stock.append(refit)
	for refit: RefitData in stock:
		_add_item(refit)


func _add_item(refit: RefitData) -> void:
	var index: int = _cards.size()
	var card: RefitCard = RefitCard.new(refit, card_height)
	card.pressed.connect(_buy.bind(index))
	var tag: VBoxContainer = VBoxContainer.new()
	tag.custom_minimum_size.x = 104.0
	tag.alignment = BoxContainer.ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var price: Label = RefitCard.make_label("", 18, GREEN)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var state: Label = RefitCard.make_label("", 11, GREY)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_child(price)
	tag.add_child(state)
	card.add_side(tag)
	_items.add_child(card)
	_cards.append(card)
	_sold.append(false)
	_price_labels.append(price)
	_state_labels.append(state)


## Why an item can't be bought right now ("" if it can, apart from the price).
func _blocked_reason(index: int) -> String:
	if _sold[index]:
		return tr("ARMORY_SOLD")
	var refit: RefitData = _cards[index].refit
	if refit.is_available():
		return ""
	if refit is FieldModData and (refit as FieldModData).effect == FieldModData.Effect.REPAIR:
		return tr("ARMORY_ARMOR_FULL")
	return tr("ARMORY_UNAVAILABLE")


func _refresh() -> void:
	_armor.text = tr("ARMORY_ARMOR") % [GameState.armor, GameState.max_armor]
	_salvage.text = tr("REFIT_SALVAGE") % GameState.salvage
	for i: int in _cards.size():
		var price: int = price_of(_cards[i].refit)
		var reason: String = _blocked_reason(i)
		_price_labels[i].text = tr("ARMORY_PRICE") % price
		_state_labels[i].text = reason if reason != "" else tr("ARMORY_UNIT")
		if reason != "":
			_price_labels[i].add_theme_color_override("font_color", GREY)
			_cards[i].modulate = Color(1.0, 1.0, 1.0, 0.45)
		else:
			_price_labels[i].add_theme_color_override("font_color", GREEN if GameState.salvage >= price else RED)
			_cards[i].modulate = Color.WHITE
		_cards[i].refresh_swap()


func _buy(index: int) -> void:
	if not _accepting:
		return
	var refit: RefitData = _cards[index].refit
	var price: int = price_of(refit)
	if _blocked_reason(index) != "":
		_deny(_blocked_reason(index))
		return
	if not GameState.spend_salvage(price):
		_deny(tr("ARMORY_SHORT"))
		return
	GameState.install_refit(refit)
	_sold[index] = true
	_show_message(tr("ARMORY_BOUGHT") % tr(refit.display_name()), GREEN)
	AudioManager.play("assimilate", -6.0)
	_refresh()


func _deny(text: String) -> void:
	AudioManager.play("denied", -4.0)
	if text != "":
		_show_message(text, RED)


func _show_message(text: String, color: Color) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)


func _on_leave_pressed() -> void:
	if not _accepting:
		return
	_accepting = false
	visible = false
	get_tree().paused = false
	finished.emit()
