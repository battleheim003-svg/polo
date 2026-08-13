extends Control

const LINEUP_TOOLS := preload("res://domain/match/lineup_tools.gd")

var seed_edit: LineEdit
var start_button: Button
var status_label: Label
var synergy_label: Label
var selected_rider_id: String = ""
var lineup: Array[String] = []
var slot_buttons: Array[Button] = []

func _ready() -> void:
	lineup = GameSession.selected_lineup.duplicate()
	if lineup.is_empty():
		lineup = GameSession.repository.teams["player"].rider_ids.duplicate()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title := Label.new()
	title.text = "Lineup Preparation"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	root.add_child(title)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	root.add_child(content)
	var slots := VBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	content.add_child(slots)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(760, 86)
		button.pressed.connect(_place_or_select_slot.bind(i))
		slots.add_child(button)
		slot_buttons.append(button)
	var roster := VBoxContainer.new()
	roster.add_theme_constant_override("separation", 8)
	content.add_child(roster)
	for rider in GameSession.repository.riders.values():
		var def: RiderDefinition = rider
		var horse: HorseDefinition = GameSession.repository.horses[def.horse_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(820, 76)
		button.text = "%s | Strike %d Ride %d Control %d Focus %d | Horse %s Stamina %d Calm %d" % [
			def.name_en, def.strike, def.ride, def.control, def.focus, horse.name, horse.stamina, horse.calmness
		]
		button.pressed.connect(func(id := def.id) -> void:
			selected_rider_id = id
			_refresh()
		)
		roster.add_child(button)
	synergy_label = Label.new()
	synergy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(synergy_label)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	root.add_child(controls)
	seed_edit = LineEdit.new()
	seed_edit.text = str(GameSession.current_seed)
	seed_edit.placeholder_text = "Seed"
	seed_edit.custom_minimum_size = Vector2(240, 64)
	controls.add_child(seed_edit)
	var commands := OptionButton.new()
	commands.custom_minimum_size = Vector2(360, 64)
	for tactic in GameSession.repository.tactics.values():
		commands.add_item(str(tactic["name_en"]))
		commands.set_item_metadata(commands.item_count - 1, str(tactic["id"]))
	commands.item_selected.connect(func(index: int) -> void: GameSession.selected_command = str(commands.get_item_metadata(index)))
	controls.add_child(commands)
	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(620, 64)
	controls.add_child(status_label)
	start_button = Button.new()
	start_button.text = "Start Match"
	start_button.custom_minimum_size = Vector2(300, 72)
	start_button.pressed.connect(_start)
	root.add_child(start_button)

func _place_or_select_slot(slot: int) -> void:
	if selected_rider_id == "":
		selected_rider_id = lineup[slot]
		_refresh()
		return
	var old_index := lineup.find(selected_rider_id)
	if old_index >= 0:
		var other := lineup[slot]
		lineup[slot] = selected_rider_id
		lineup[old_index] = other
	else:
		lineup[slot] = selected_rider_id
	selected_rider_id = ""
	_refresh()

func _refresh() -> void:
	for i in range(slot_buttons.size()):
		var rider_id := lineup[i]
		var rider: RiderDefinition = GameSession.repository.riders[rider_id]
		var horse: HorseDefinition = GameSession.repository.horses[rider.horse_id]
		var role := LINEUP_TOOLS.role_for_slot(i)
		slot_buttons[i].text = "Slot %d %s | %s | Fit %.2f %s | Horse %s %s" % [
			i + 1, role, rider.name_en, LINEUP_TOOLS.role_fit(rider, role), LINEUP_TOOLS.role_fit_label(rider, role), horse.name, horse.trait_id
		]
		slot_buttons[i].disabled = false
	var synergies := LINEUP_TOOLS.active_synergies(GameSession.repository, lineup)
	var synergy_texts: Array[String] = []
	for synergy in synergies:
		synergy_texts.append("%s: %s" % [synergy["name"], synergy["effect"]])
	synergy_label.text = "Active synergies: %s" % ("; ".join(synergy_texts) if synergy_texts.size() > 0 else "none")
	var validation: Dictionary = LINEUP_TOOLS.validate_lineup(GameSession.repository, lineup)
	status_label.text = str(validation["reason"])
	start_button.disabled = not bool(validation["ok"])

func _start() -> void:
	var validation := GameSession.set_lineup(lineup)
	if not bool(validation["ok"]):
		status_label.text = str(validation["reason"])
		return
	var seed_value := int(seed_edit.text)
	GameSession.start_match(seed_value)
	get_tree().change_scene_to_file("res://scenes/match/match.tscn")
