class_name ImportClientConfirmation
extends ConfirmationDialog

const block_key: StringName = &"block"

@export var transfer_selection_button: Button
@export var transfer_all_button: Button

@export_group("existing_client")
@export var existing_client_name_label: Label
@export var existing_client_id_label: Label
@export var existing_client_site_label: Label
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
	transfer_all_button.pressed.connect(_transfer_all_client_data)
	transfer_selection_button.pressed.connect(_transfer_selected_data)

	import_client_block_boxes = {
		Schedule.Block.MONDAY_AM: new_client_mon_am_box,
		Schedule.Block.MONDAY_PM: new_client_mon_pm_box,
		Schedule.Block.TUESDAY_AM: new_client_tues_am_box,
		Schedule.Block.TUESDAY_PM: new_client_tues_pm_box,
		Schedule.Block.WEDNESDAY_AM: new_client_wed_am_box,
		Schedule.Block.WEDNESDAY_PM: new_client_wed_pm_box,
		Schedule.Block.THURSDAY_AM: new_client_thurs_am_box,
		Schedule.Block.THURSDAY_PM: new_client_thurs_pm_box,
		Schedule.Block.FRIDAY_AM: new_client_fri_am_box,
		Schedule.Block.FRIDAY_PM: new_client_fri_pm_box
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

	import_client_labels = {
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
	set_up_new_client(new_client)
	set_up_saved_client(existing_client)


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
	existing_client_site_label.text = Schedule.get_site_string(client.scheduled_site)

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


func _transfer_all_client_data() -> void:
	pass


func _transfer_selected_data() -> void:
	pass
