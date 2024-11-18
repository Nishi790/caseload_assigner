class_name ImportClientConfirmation
extends AcceptDialog

signal transfer_complete

const block_key: StringName = &"block"

@export var transfer_selection_button: Button
@export var transfer_all_button: Button
@export var discard_changes: Button

@export_group("existing_client")
@export var existing_client_name_label: Label
@export var existing_client_id_label: Label
@export var existing_client_site_selector: OptionButton
@export var existing_client_mon_am_label: Label
@export var existing_client_mon_pm_label: Label
@export var existing_client_tues_am_label: Label
@export var existing_client_tues_pm_label: Label
@export var existing_client_wed_am_label: Label
@export var existing_client_wed_pm_label: Label
@export var existing_client_thurs_am_label: Label
@export var existing_client_thurs_pm_label: Label
@export var existing_client_fri_am_label: Label
@export var existing_client_fri_pm_label: Label

@export_group("new_client")
@export var new_client_name_label: Label
@export var new_client_id_label: Label
@export var new_client_site_label: Label
@export var new_client_mon_am_label: Label
@export var new_client_mon_pm_label: Label
@export var new_client_tues_am_label: Label
@export var new_client_tues_pm_label: Label
@export var new_client_wed_am_label: Label
@export var new_client_wed_pm_label: Label
@export var new_client_thurs_am_label: Label
@export var new_client_thurs_pm_label: Label
@export var new_client_fri_am_label: Label
@export var new_client_fri_pm_label: Label

@export var new_client_site_box: CheckBox
@export var new_client_mon_am_box: CheckBox
@export var new_client_mon_pm_box: CheckBox
@export var new_client_tues_am_box: CheckBox
@export var new_client_tues_pm_box: CheckBox
@export var new_client_wed_am_box: CheckBox
@export var new_client_wed_pm_box: CheckBox
@export var new_client_thurs_am_box: CheckBox
@export var new_client_thurs_pm_box: CheckBox
@export var new_client_fri_am_box: CheckBox
@export var new_client_fri_pm_box: CheckBox

var saved_client: Client
var imported_client: Client

var import_client_block_boxes: Dictionary #block: checkbox
var import_client_labels: Dictionary
var saved_client_block_labels: Dictionary

func _ready() -> void:
	transfer_all_button.pressed.connect(_set_up_transfer_all_client_data)
	transfer_selection_button.pressed.connect(_set_up_transfer_selected_data)
	about_to_popup.connect(_on_about_to_pop_up)

	import_client_block_boxes = {
		new_client_mon_am_box: Schedule.Block.MONDAY_AM,
		new_client_mon_pm_box: Schedule.Block.MONDAY_PM,
		new_client_tues_am_box: Schedule.Block.TUESDAY_AM,
		new_client_tues_pm_box: Schedule.Block.TUESDAY_PM,
		new_client_wed_am_box: Schedule.Block.WEDNESDAY_AM,
		new_client_wed_pm_box: Schedule.Block.WEDNESDAY_PM,
		new_client_thurs_am_box: Schedule.Block.THURSDAY_AM,
		new_client_thurs_pm_box: Schedule.Block.THURSDAY_PM,
		new_client_fri_am_box: Schedule.Block.FRIDAY_AM,
		new_client_fri_pm_box: Schedule.Block.FRIDAY_PM
		}

	import_client_labels = {
		Schedule.Block.MONDAY_AM: new_client_mon_am_label,
		Schedule.Block.MONDAY_PM: new_client_mon_pm_label,
		Schedule.Block.TUESDAY_AM: new_client_tues_am_label,
		Schedule.Block.TUESDAY_PM: new_client_tues_pm_label,
		Schedule.Block.WEDNESDAY_AM: new_client_wed_am_label,
		Schedule.Block.WEDNESDAY_PM: new_client_wed_pm_label,
		Schedule.Block.THURSDAY_AM: new_client_thurs_am_label,
		Schedule.Block.THURSDAY_PM: new_client_thurs_pm_label,
		Schedule.Block.FRIDAY_AM: new_client_fri_am_label,
		Schedule.Block.FRIDAY_PM: new_client_fri_pm_label
	}

	saved_client_block_labels = {
		Schedule.Block.MONDAY_AM: existing_client_mon_am_label,
		Schedule.Block.MONDAY_PM: existing_client_mon_pm_label,
		Schedule.Block.TUESDAY_AM: existing_client_tues_am_label,
		Schedule.Block.TUESDAY_PM: existing_client_tues_pm_label,
		Schedule.Block.WEDNESDAY_AM: existing_client_wed_am_label,
		Schedule.Block.WEDNESDAY_PM: existing_client_wed_pm_label,
		Schedule.Block.THURSDAY_AM: existing_client_thurs_am_label,
		Schedule.Block.THURSDAY_PM: existing_client_thurs_pm_label,
		Schedule.Block.FRIDAY_AM: existing_client_fri_am_label,
		Schedule.Block.FRIDAY_PM: existing_client_fri_pm_label
	}

	connect_block_data()


func load_clients(existing_client: Client, new_client: Client) -> void:
	saved_client = existing_client
	imported_client = new_client
	set_up_new_client(imported_client)
	set_up_saved_client(saved_client)


func set_up_new_client(new_client: Client) -> void:
	new_client_name_label.text = new_client.client_name
	new_client_id_label.text = str(new_client.AC_id)
	new_client_site_label.text = Schedule.get_site_string(new_client.scheduled_site)
	for block: Schedule.Block in new_client.scheduled_blocks:
		if new_client.assigned_therapists.has(block):
			var block_label: Label = import_client_labels[block]
			var therapist = new_client.assigned_therapists[block]
			if therapist is Therapist:
				block_label.text = therapist.therapist_name
			elif therapist is TempTherapist:
				block_label.text = therapist.name
			else:
				block_label.text = str(therapist)


func set_up_saved_client(client: Client) -> void:
	existing_client_name_label.text = client.client_name
	existing_client_id_label.text = str(client.AC_id)
	if client.scheduled_site == Schedule.Site.ALL_SITES:
		existing_client_site_selector.select(0)
	else:
		var index: int = existing_client_site_selector.get_item_index(client.scheduled_site)
		existing_client_site_selector.select(index)

	for block: Schedule.Block in client.scheduled_blocks:
		if client.assigned_therapists.has(block):
			var block_label: Label = saved_client_block_labels[block]
			var therapist = client.assigned_therapists[block]
			if therapist is Therapist:
				block_label.text = therapist.therapist_name
			elif therapist is TempTherapist:
				block_label.text = therapist.name
			else:
				block_label.text = str(therapist)


func connect_block_data() -> void:
	new_client_mon_am_box.set_meta(block_key, Schedule.Block.MONDAY_AM)
	new_client_mon_pm_box.set_meta(block_key, Schedule.Block.MONDAY_PM)
	new_client_tues_am_box.set_meta(block_key, Schedule.Block.TUESDAY_AM)
	new_client_tues_pm_box.set_meta(block_key, Schedule.Block.TUESDAY_PM)
	new_client_wed_am_box.set_meta(block_key, Schedule.Block.WEDNESDAY_AM)
	new_client_wed_pm_box.set_meta(block_key, Schedule.Block.WEDNESDAY_PM)
	new_client_thurs_am_box.set_meta(block_key, Schedule.Block.THURSDAY_AM)
	new_client_thurs_pm_box.set_meta(block_key, Schedule.Block.THURSDAY_PM)
	new_client_fri_am_box.set_meta(block_key, Schedule.Block.FRIDAY_AM)
	new_client_fri_pm_box.set_meta(block_key, Schedule.Block.FRIDAY_PM)


func _set_up_transfer_all_client_data() -> void:
	if confirmed.is_connected(_transfer_selected_data):
		confirmed.disconnect(_transfer_selected_data)
	if not confirmed.is_connected(_transfer_all_client_data):
		confirmed.connect(_transfer_all_client_data)


func _set_up_transfer_selected_data() -> void:
	if confirmed.is_connected(_transfer_all_client_data):
		confirmed.disconnect(_transfer_all_client_data)
	if not confirmed.is_connected(_transfer_selected_data):
		confirmed.connect(_transfer_selected_data)


func _transfer_all_client_data() -> void:
	saved_client.update_scheduled_blocks(imported_client.scheduled_blocks, false)
	if imported_client.scheduled_site != Schedule.Site.ALL_SITES:
		saved_client.scheduled_site = imported_client.scheduled_site
	elif existing_client_site_selector.get_selected_id() < 10:
		saved_client.scheduled_site = existing_client_site_selector.get_selected_id()

	saved_client.assigned_therapists = imported_client.assigned_therapists
	saved_client.scheduled_blocks = imported_client.scheduled_blocks
	saved_client.unfilled_slots = []
	transfer_complete.emit()


func _transfer_selected_data() -> void:
	if new_client_site_box.button_pressed and imported_client.scheduled_site != Schedule.Site.ALL_SITES:
		saved_client.scheduled_site = imported_client.scheduled_site
	else: saved_client.scheduled_site = existing_client_site_selector.get_selected_id()

	var blocks_affected: Array[Schedule.Block] = []
	for box: CheckBox in import_client_block_boxes:
		var block: Schedule.Block = import_client_block_boxes[box]
		if box.button_pressed:
			blocks_affected.append(block)
		elif imported_client.assigned_therapists.has(block):
			var assigned_thx = imported_client.assigned_therapists[block]
			if assigned_thx is TempTherapist and assigned_thx.scheduled_visits.has(block):
				assigned_thx.remove_block(block)
				assigned_thx.add_admin(block, Schedule.Site.ALL_SITES)

	for block: Schedule.Block in blocks_affected:
		if imported_client.assigned_therapists.has(block):
			if not saved_client.scheduled_blocks.has(block):
				saved_client.scheduled_blocks.append(block)
			if saved_client.unfilled_slots.has(block):
				saved_client.unfilled_slots.erase(block)
		else:
			saved_client.clear_block(block)
			if saved_client.assigned_therapists.has(block):
				var thx: Therapist = saved_client.assigned_therapists[block]
				thx.free_slot(block)
				saved_client.assigned_therapists.erase(block)
	transfer_complete.emit()


func _on_about_to_pop_up() -> void:
	for box: CheckBox in import_client_block_boxes:
		box.set_pressed_no_signal(false)
	for label: Label in import_client_labels.values():
		label.text = ""
	for label: Label in saved_client_block_labels.values():
		label.text = ""
	new_client_site_box.set_pressed_no_signal(false)

	existing_client_site_selector.selected = -1
