class_name RequestedSlotDisplay
extends PanelContainer

signal requested_slots_removed(affected_display: RequestedSlotDisplay)
signal requested_slots_changed(affected_display: RequestedSlotDisplay)
signal request_accepted(affected_display: RequestedSlotDisplay)

@export var client_label: Label
@export var site_label: Label
@export var slots_label: Label
@export var accept_button: Button

var client: Client


func _ready() -> void:
	accept_button.pressed.connect(_accept_client_request)


func initiate_display(new_client: Client) -> void:
	client = new_client
	client_label.set_text(client.client_name)
	site_label.set_text(Schedule.get_site_string(client.requested_site))
	_set_slot_list_text()


func _set_slot_list_text() -> void:
	var slot_list: PackedStringArray = PackedStringArray()
	for block: Schedule.Block in client.requested_blocks:
		slot_list.append(Schedule.get_block_string(block))
	var slot_list_string: String = ", ".join(slot_list)
	slots_label.set_text(slot_list_string)


func refresh_display() -> void:
	if client.requested_blocks.is_empty():
		requested_slots_removed.emit(self)
	else:
		_set_slot_list_text()
		requested_slots_changed.emit(self)


func _accept_client_request() -> void:
	client.schedule_requested_blocks()
	request_accepted.emit(self)
