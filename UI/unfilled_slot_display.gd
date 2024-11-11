class_name UnfilledClientDisplay
extends HBoxContainer

signal unfilled_slots_now_empty(affected_display: UnfilledClientDisplay)

@export var client_label: Label
@export var site_label: Label
@export var slots_label: Label

var client: Client

func initiate_display(new_client: Client) -> void:
	client = new_client
	client_label.set_text(client.client_name)
	site_label.set_text(Schedule.get_site_string(client.scheduled_site))
	_set_slot_list_text()




func _set_slot_list_text() -> void:
	var slot_list: PackedStringArray = PackedStringArray()
	for block: Schedule.Block in client.unfilled_slots:
		slot_list.append(Schedule.get_block_string(block))
	var slot_list_string: String = ", ".join(slot_list)
	slots_label.set_text(slot_list_string)


func refresh_display() -> void:
	if client.unfilled_slots.is_empty():
		unfilled_slots_now_empty.emit(self)
	else:
		_set_slot_list_text()
