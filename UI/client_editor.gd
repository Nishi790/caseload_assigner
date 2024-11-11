class_name ClientEditor
extends PanelContainer

enum EditState {NEW, EDIT}

const block_name: StringName = &"block"

@export var confirm_button: Button
@export var client_name_line: LineEdit
@export var client_id_setter: SpinBox
@export var rba_selector: OptionButton
@export var edit_button: Button

@export var mon_am_current: CheckBox
@export var tues_am_current: CheckBox
@export var wed_am_current: CheckBox
@export var thurs_am_current: CheckBox
@export var fri_am_current: CheckBox

@export var mon_pm_current: CheckBox
@export var tues_pm_current: CheckBox
@export var wed_pm_current: CheckBox
@export var thurs_pm_current: CheckBox
@export var fri_pm_current: CheckBox

@export var current_site_selector: OptionButton

@export var mon_am_requested: CheckBox
@export var tues_am_requested: CheckBox
@export var wed_am_requested: CheckBox
@export var thurs_am_requested: CheckBox
@export var fri_am_requested: CheckBox

@export var mon_pm_requested: CheckBox
@export var tues_pm_requested: CheckBox
@export var wed_pm_requested: CheckBox
@export var thurs_pm_requested: CheckBox
@export var fri_pm_requested: CheckBox

@export var requested_site_selector: OptionButton

@export var client_selector: ClientSelector

var current_checkboxes: Array[CheckBox]
var requested_checkboxes: Array[CheckBox]

var state: EditState = EditState.NEW
var client: Client
var tab_id: int


func _ready() -> void:
	confirm_button.pressed.connect(confirm_edits)
	current_checkboxes = [mon_am_current, mon_pm_current, tues_am_current, tues_pm_current, wed_am_current,
		wed_pm_current, thurs_am_current, thurs_pm_current, fri_am_current, fri_pm_current]
	requested_checkboxes = [mon_am_requested, mon_pm_requested, tues_am_requested, tues_pm_requested, wed_am_requested,
		wed_pm_requested, thurs_am_requested, thurs_pm_requested, fri_am_requested, fri_pm_requested]

	mon_am_current.set_meta(block_name, Schedule.Block.MONDAY_AM)
	mon_am_requested.set_meta(block_name, Schedule.Block.MONDAY_AM)
	mon_pm_current.set_meta(block_name, Schedule.Block.MONDAY_PM)
	mon_pm_requested.set_meta(block_name, Schedule.Block.MONDAY_PM)

	tues_am_current.set_meta(block_name, Schedule.Block.TUESDAY_AM)
	tues_am_requested.set_meta(block_name, Schedule.Block.TUESDAY_AM)
	tues_pm_current.set_meta(block_name, Schedule.Block.TUESDAY_PM)
	tues_pm_requested.set_meta(block_name, Schedule.Block.TUESDAY_PM)

	wed_am_current.set_meta(block_name, Schedule.Block.WEDNESDAY_AM)
	wed_am_requested.set_meta(block_name, Schedule.Block.WEDNESDAY_AM)
	wed_pm_current.set_meta(block_name, Schedule.Block.WEDNESDAY_PM)
	wed_pm_requested.set_meta(block_name, Schedule.Block.WEDNESDAY_PM)

	thurs_am_current.set_meta(block_name, Schedule.Block.THURSDAY_AM)
	thurs_am_requested.set_meta(block_name, Schedule.Block.THURSDAY_AM)
	thurs_pm_current.set_meta(block_name, Schedule.Block.THURSDAY_PM)
	thurs_pm_requested.set_meta(block_name, Schedule.Block.THURSDAY_PM)

	fri_am_current.set_meta(block_name, Schedule.Block.FRIDAY_AM)
	fri_am_requested.set_meta(block_name, Schedule.Block.FRIDAY_AM)
	fri_pm_current.set_meta(block_name, Schedule.Block.FRIDAY_PM)
	fri_pm_requested.set_meta(block_name, Schedule.Block.FRIDAY_PM)

	current_site_selector.set_item_metadata(1, Schedule.Site.COLONNADE)
	current_site_selector.set_item_metadata(2, Schedule.Site.LANCASTER)
	current_site_selector.set_item_metadata(3, Schedule.Site.KANATA)
	current_site_selector.set_item_metadata(4, Schedule.Site.PEMBROKE)

	requested_site_selector.set_item_metadata(1, Schedule.Site.COLONNADE)
	requested_site_selector.set_item_metadata(2, Schedule.Site.LANCASTER)
	requested_site_selector.set_item_metadata(3, Schedule.Site.KANATA)
	requested_site_selector.set_item_metadata(4, Schedule.Site.PEMBROKE)

	var index: int = 1
	for thx: Therapist in CaseloadData.active_staff:
		if thx.therapist_type == Therapist.Type.RBA:
			rba_selector.add_item(thx.therapist_name)
			rba_selector.set_item_metadata(index, thx)
			index += 1

	client_selector.client_selected.connect(edit_client)
	edit_button.pressed.connect(client_selector.popup_centered)


func _on_return_to_tab(idx: int) -> void:
	if idx == tab_id:
		update_rba_list()


func update_rba_list() -> void:
	var number_of_items: int = rba_selector.item_count
	var notated_rbas: Array[Therapist] = []
	for selector_index: int in number_of_items:
		if selector_index == 0:
			continue
		notated_rbas.append(rba_selector.get_item_metadata(selector_index))

	var new_addition_index: int = number_of_items
	for thx: Therapist in CaseloadData.active_staff:
		if thx.therapist_type == Therapist.Type.RBA and not notated_rbas.has(thx):
			rba_selector.add_item(thx.therapist_name)
			rba_selector.set_item_metadata(new_addition_index, thx)
			new_addition_index += 1



func confirm_edits() -> void:
	if state == EditState.NEW:
		client = Client.new()
		client.client_name = client_name_line.text.strip_edges()
		client.AC_id = client_id_setter.value
		for box: CheckBox in current_checkboxes:
			if box.button_pressed == true:
				client.add_current_block(box.get_meta(block_name))

		for box: CheckBox in requested_checkboxes:
			if box.button_pressed == true:
				client.add_requested_block(box.get_meta(block_name))

		client.scheduled_site = current_site_selector.get_item_metadata(current_site_selector.selected)
		client.requested_site = requested_site_selector.get_item_metadata(requested_site_selector.selected)
		client.assigned_RBA = rba_selector.get_item_metadata(rba_selector.selected)
		if client.assigned_RBA:
			client.rba_name = client.assigned_RBA.therapist_name
		CaseloadData.active_clients.append(client)

	elif state == EditState.EDIT:
		if not client.client_name.matchn(client_name_line.text.strip_edges()):
			client.client_name = client_name_line.text.strip_edges()

		var checked_boxes: Array[Schedule.Block] = []
		for check_box: CheckBox in current_checkboxes:
			if check_box.button_pressed:
				checked_boxes.append(check_box.get_meta(block_name))

		client.update_scheduled_blocks(checked_boxes, false)

		var requested_boxes: Array[Schedule.Block] = []

		for check_box: CheckBox in requested_checkboxes:
			if check_box.button_pressed:
				requested_boxes.append(check_box.get_meta(block_name))

		client.update_scheduled_blocks(requested_boxes, true)

		var requested_site: Schedule.Site = requested_site_selector.get_item_metadata(requested_site_selector.selected)
		var scheduled_site: Schedule.Site = current_site_selector.get_item_metadata(current_site_selector.selected)
		if scheduled_site != client.scheduled_site:
			client.scheduled_site = scheduled_site
		if requested_site != client.requested_site:
			client.requested_site = requested_site

		var rba: Therapist = rba_selector.get_item_metadata(rba_selector.selected)
		if rba != client.assigned_RBA:
			client.assigned_RBA = rba
			client.rba_name = rba.therapist_name

	clear_form()


func clear_form() -> void:
	state = EditState.NEW
	client_name_line.clear()
	client_id_setter.set_value_no_signal(0)
	client = null

	for box: CheckBox in current_checkboxes:
		box.set_pressed_no_signal(false)

	for box: CheckBox in requested_checkboxes:
		box.set_pressed_no_signal(false)

	current_site_selector.select(0)
	requested_site_selector.select(0)


func edit_client(new_client: Client) -> void:
	state = EditState.EDIT
	client = new_client
	client_id_setter.set_value_no_signal(client.AC_id)
	client_name_line.text = client.client_name

	for box: CheckBox in current_checkboxes:
		var block: Schedule.Block = box.get_meta(block_name)
		if client.scheduled_blocks.has(block):
			box.set_pressed_no_signal(true)
		elif client.unfilled_slots.has(block):
			box.set_pressed_no_signal(true)

	for box: CheckBox in requested_checkboxes:
		var block: Schedule.Block = box.get_meta(block_name)
		if client.requested_blocks.has(block):
			box.set_pressed_no_signal(true)

	current_site_selector.select(client.scheduled_site + 1)
	requested_site_selector.select(client.requested_site + 1)

	for item_index in rba_selector.item_count:
		var RBA: Therapist = rba_selector.get_item_metadata(item_index)
		if RBA == client.assigned_RBA:
			rba_selector.select(item_index)
			return
