class_name ScheduleView
extends PanelContainer


var tab_id: int


@export var double_booking_button: Button
@export var client_entry_scene: PackedScene
@export var therapist_entry_scene: PackedScene

@export var client_schedule_container: VBoxContainer
@export var staff_schedule_container: VBoxContainer
@export var site_selector: OptionButton
@export var confirm_delete: ConfirmationDialog
@export var double_booking_panel: PopupPanel


var displayed_site: Schedule.Site

var displayed_clients: Array[PersonScheduleEntry]
var displayed_therapists: Array[TherapistEntry]


func _ready() -> void:
	double_booking_button.pressed.connect(check_for_double_bookings)
	site_selector.item_selected.connect(new_site_selected)
	displayed_site = Schedule.Site.ALL_SITES
	display_clients(displayed_site)
	display_staff()


func _on_return_to_tab(id: int) -> void:
	if id == tab_id:
		CaseloadData.alphabetize_lists()
		display_clients(displayed_site)
		display_staff()


func display_clients(selected_site: Schedule.Site) -> void:

	for client: Node in displayed_clients:
		client.queue_free()

	displayed_clients.clear()

	for client: Client in CaseloadData.alphabetical_clients:
		if client.scheduled_site != selected_site and displayed_site != Schedule.Site.ALL_SITES:
			continue
		var new_entry: PersonScheduleEntry = client_entry_scene.instantiate()
		client_schedule_container.add_child(new_entry)
		new_entry.set_up_for_client(client)
		new_entry.assignment_changed.connect(_update_affected_displays)
		new_entry.delete_button.pressed.connect(confirm_delete_client.bind(client))
		displayed_clients.append(new_entry)


func display_staff() -> void:
	for thx: Node in displayed_therapists:
		thx.queue_free()

	displayed_therapists.clear()

	for thx: Therapist in CaseloadData.alphabetical_staff:
		if displayed_site != Schedule.Site.ALL_SITES:
			if not thx.work_schedule.values().has(displayed_site):
				continue
		var new_entry: TherapistEntry = therapist_entry_scene.instantiate()
		staff_schedule_container.add_child(new_entry)
		new_entry.set_therapist(thx, displayed_site)
		new_entry.delete_button.pressed.connect(confirm_delete_therapist.bind(new_entry.therapist))
		displayed_therapists.append(new_entry)


func _update_affected_displays(affected_therapists: Array[Therapist], block: Schedule.Block) -> void:
	_update_therapist_display(affected_therapists)
	for client_display: PersonScheduleEntry in displayed_clients:
		client_display.resort_thx_selector(block)


func _update_therapist_display(affected_therapists: Array[Therapist]) -> void:
	for entry: TherapistEntry in displayed_therapists:
		if affected_therapists.has(entry.therapist):
			entry.update_display(displayed_site)
			affected_therapists.erase(entry.therapist)

	if not affected_therapists.is_empty():
		for thx: Therapist in affected_therapists:
			var new_entry: TherapistEntry = therapist_entry_scene.instantiate()
			staff_schedule_container.add_child(new_entry)
			new_entry.set_therapist(thx)
			displayed_therapists.append(new_entry)


func new_site_selected(index: int) -> void:
	match index:
		0:
			displayed_site = Schedule.Site.ALL_SITES
		1:
			displayed_site = Schedule.Site.COLONNADE
		2:
			displayed_site = Schedule.Site.LANCASTER
		3:
			displayed_site = Schedule.Site.KANATA
		4:
			displayed_site = Schedule.Site.PEMBROKE

	display_clients(displayed_site)
	display_staff()


func confirm_delete_therapist(thx: Therapist) -> void:
	confirm_delete.popup_centered()
	if confirm_delete.confirmed.is_connected(delete_client):
		confirm_delete.confirmed.disconnect(delete_client)
	confirm_delete.confirmed.connect(delete_therapist.bind(thx), ConnectFlags.CONNECT_ONE_SHOT)
	confirm_delete.dialog_text = "Are you sure you want to delete the therapist %s"  % thx.therapist_name


func delete_therapist(thx: Therapist) -> void:
	CaseloadData.delete_therapist(thx)
	var entry_to_erase: TherapistEntry
	for entry: TherapistEntry in displayed_therapists:
		if entry.therapist == thx:
			entry_to_erase = entry
			break
	displayed_therapists.erase(entry_to_erase)
	entry_to_erase.queue_free()


func confirm_delete_client(client: Client):
	confirm_delete.popup_centered()
	confirm_delete.confirmed.connect(delete_client.bind(client), ConnectFlags.CONNECT_ONE_SHOT)
	if confirm_delete.confirmed.is_connected(delete_therapist):
		confirm_delete.confirmed.disconnect(delete_therapist)
	confirm_delete.dialog_text = "Are you sure you want to delete the client %s" % client.client_name


func delete_client(client: Client):
	var thx_to_update: Array[Therapist]
	for thx: Therapist in client.assigned_therapists.values():
		thx_to_update.append(thx)
	CaseloadData.delete_client(client)
	var client_display_to_delete: PersonScheduleEntry
	for display: PersonScheduleEntry in displayed_clients:
		if display.client == client:
			client_display_to_delete = display
			break
	client_display_to_delete.queue_free()
	displayed_clients.erase(client_display_to_delete)
	_update_therapist_display(thx_to_update)


func check_for_double_bookings() -> void:
	var double_booked_therapists: Dictionary = {}  #Therapist:Dictionary {Block: [Clients]}
	for id: int in CaseloadData.active_staff:
		var therapist: Therapist = CaseloadData.active_staff[id]
		for block: Schedule.Block in therapist.scheduled_blocks:
			var assigned_client: Client = therapist.scheduled_blocks[block]
			for client: Client in CaseloadData.active_clients.values():
				if client == assigned_client:
					continue
				if client.assigned_therapists.has(block):
					var assigned_thx = client.assigned_therapists[block]
					if assigned_thx is Therapist and assigned_thx.AC_id == id:
						add_double_booking(double_booked_therapists, therapist, block, assigned_client, client)
					elif assigned_thx is TempTherapist and assigned_thx.id == id:
						add_double_booking(double_booked_therapists, therapist, block, assigned_client, client)

	double_booking_panel.popup_centered()
	double_booking_panel.set_up(double_booked_therapists)


func add_double_booking(double_booking_dict: Dictionary, therapist: Therapist, block: Schedule.Block, assigned_client: Client, double_booking: Client) -> void:
	if double_booking_dict.has(therapist):
		var double_booking_entry: Dictionary = double_booking_dict[therapist]
		if double_booking_entry.has(block):
			double_booking_entry[block].append(double_booking)
		else:
			double_booking_entry[block] = [double_booking]
	else:
		double_booking_dict[therapist] = {block:[assigned_client, double_booking]}
