class_name DoubleBookingPanel
extends PopupPanel


@export var keep_entry_scene: PackedScene
@export var entry_container: VBoxContainer
@export var therapist_name_label: Label
@export var block_label: Label
@export var site_label: Label

var double_booking_dict: Dictionary

var double_booking_array: Array[Dictionary]

var active_booking: Dictionary


func _ready() -> void:
	visibility_changed.connect(visibility_changing)


func visibility_changing() -> void:
	if not visible:
		print("hiding")
	else:
		print("Showing pop-up")


func set_up(booking_dict: Dictionary) -> void:
	double_booking_dict = booking_dict
	for thx: Therapist in double_booking_dict:

		for block in double_booking_dict[thx]:
			var double_book: Dictionary = {}
			double_book["block"] = block
			double_book["therapist"] = thx
			double_book["clients"] = double_booking_dict[thx][block]
			double_booking_array.append(double_book)

	active_booking = double_booking_array.pop_back()
	display_booking()

func display_booking() -> void:
	for child: Node in entry_container.get_children():
		child.queue_free()
	therapist_name_label.text = active_booking["therapist"].therapist_name
	block_label.text = Schedule.get_block_string(active_booking["block"])
	site_label.text = Schedule.get_site_string(active_booking["therapist"].work_schedule[active_booking["block"]])
	var clients: Array[Client] = []
	clients.assign(active_booking["clients"])
	for client: Client in clients:
		var confirm_entry: KeepBookingEntry = keep_entry_scene.instantiate()
		confirm_entry.set_up(client)
		entry_container.add_child(confirm_entry)
		confirm_entry.client_kept.connect(keep_selected_booking)


func keep_selected_booking(client: Client) -> void:
	var block: Schedule.Block = active_booking["block"]
	var thx: Therapist = active_booking["therapist"]
	var clients: Array[Client] = []
	clients.assign(active_booking["clients"])
	for booked_client in clients:
		booked_client.clear_block(block)

	client.update_assigned_therapist(block, thx)

	if not double_booking_array.is_empty():
		active_booking = double_booking_array.pop_back()
		display_booking()
	else:
		double_booking_dict.clear()
		hide()
