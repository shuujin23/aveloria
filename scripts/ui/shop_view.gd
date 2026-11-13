extends PanelContainer
## Tampilan toko: kartu berikon untuk tiap barang (ikon, nama, harga, jumlah yang dimiliki),
## ditambah kartu "Perbesar tas". Pemakainya memanggil open() lalu menanggapi sinyal
## buy / upgrade / closed, dan memanggil open() lagi setelah keadaan berubah.

signal buy(item_id: String)
signal upgrade
signal closed

const SPRITES := "res://assets/sprites/"
const COLUMNS := 3
const CARD_SIZE := Vector2(196, 84)
const ICON_SIZE := Vector2(48, 48)
const COLOR_GOLD := Color("c9a85c")
const UPGRADE := "__tas"  # id kartu perbesar tas

var _title: Label
var _purse: Label
var _grid: GridContainer
var _detail: Label


func _init() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.13, 0.96)
	style.border_color = COLOR_GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	visible = false

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.text = Loc.t("Toko")
	_title.add_theme_color_override("font_color", COLOR_GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_purse = Label.new()
	header.add_child(_purse)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	column.add_child(_grid)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(COLUMNS * (CARD_SIZE.x + 8), 46)
	_detail.add_theme_font_size_override("font_size", 15)
	column.add_child(_detail)

	var done := Button.new()
	done.text = Loc.t("Selesai")
	done.focus_entered.connect(func() -> void: Audio.sfx("ui_move"))
	done.pressed.connect(func() -> void:
		Audio.sfx("ui_ok")
		closed.emit())
	column.add_child(done)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_cancel")
		closed.emit()


func set_shop_name(shop_name: String) -> void:
	_title.text = shop_name


## Tampilkan toko dengan daftar barang `stock`. focus_id = kartu yang langsung disorot;
## message = teks di bawah kartu sampai pemain menyorot kartu lain.
func open(stock: Array, focus_id: String = "", message: String = "") -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_purse.text = Loc.t("Emas: %d      Tas %d/%d slot") % [Game.gold, Game.slots_used(), Game.bag_slots]

	var wanted: Button = null
	var first: Button = null
	for item_id: String in stock:
		var item: Dictionary = Db.ITEMS[item_id]
		var reason := ""
		if not Game.can_add(item_id):
			reason = Loc.t("Tas penuh. Pakai atau buang barang, atau perbesar tas.")
		elif Game.gold < int(item.price):
			reason = Loc.t("Emas belum cukup.")
		var card := _card("icon_%s" % item_id, Loc.t(item.name), Loc.t("%d emas") % item.price,
			Loc.t("punya %d") % int(Game.items.get(item_id, 0)), Loc.t(item.desc), reason,
			func() -> void: buy.emit(item_id))
		if first == null:
			first = card
		if item_id == focus_id:
			wanted = card

	var price := Db.bag_upgrade_price(Game.bag_slots)
	if price >= 0:
		var card := _card("icon_tas", Loc.t("Perbesar tas"), Loc.t("%d emas") % price,
			Loc.t("%d -> %d slot") % [Game.bag_slots, min(Db.BAG_MAX, Game.bag_slots + Db.BAG_STEP)],
			Loc.t("Menambah %d slot tas. Tiap slot memuat %d barang sejenis; maksimal %d slot.") % [Db.BAG_STEP, Db.STACK_MAX, Db.BAG_MAX],
			Loc.t("Emas belum cukup.") if Game.gold < price else "",
			func() -> void: upgrade.emit())
		if focus_id == UPGRADE:
			wanted = card

	visible = true
	_detail.text = Loc.t("Sorot barang untuk melihat khasiatnya; tekan untuk membeli.")
	(wanted if wanted != null else first).grab_focus()
	if message != "":
		_detail.text = message


## Satu kartu: ikon di kiri; nama, harga, dan keterangan di kanan.
## reason = alasan tidak bisa dibeli (kartu diredupkan dan menekannya hanya menampilkan alasan itu).
func _card(icon_name: String, title: String, price: String, note: String, desc: String, reason: String, on_buy: Callable) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("243044") if state == "hover" else Color("1a2332")
		box.border_color = Color("ffd866") if state == "focus" else Color("3a4860")
		if state == "focus":
			box.bg_color = Color(0, 0, 0, 0)
		box.set_border_width_all(2)
		box.set_corner_radius_all(4)
		card.add_theme_stylebox_override(state, box)

	var body := Control.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.modulate.a = 0.45 if reason != "" else 1.0
	card.add_child(body)
	var icon := TextureRect.new()
	icon.texture = load(SPRITES + icon_name + ".png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = ICON_SIZE
	icon.position = Vector2(10, (CARD_SIZE.y - ICON_SIZE.y) * 0.5)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(icon)
	_text(body, title, Vector2(68, 8), 17, Color.WHITE)
	_text(body, price, Vector2(68, 32), 16, Color("ffd866"))
	_text(body, note, Vector2(68, 54), 13, Color(1, 1, 1, 0.65))

	var show_detail := func() -> void:
		_detail.text = desc if reason == "" else "%s  (%s)" % [desc, reason]
		Audio.sfx("ui_move")
	card.focus_entered.connect(show_detail)
	card.mouse_entered.connect(show_detail)
	card.pressed.connect(func() -> void:
		if reason == "":
			on_buy.call()
		else:
			Audio.sfx("ui_cancel")
			_detail.text = reason)
	_grid.add_child(card)
	return card


func _text(parent: Control, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
