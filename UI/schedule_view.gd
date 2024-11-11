class_name ScheduleView
extends PanelContainer


var tab_id: int

@export var client_entry_scene: PackedScene
@export var therapist_entry_scene: PackedScene

@export var client_schedule_container: VBoxContainer
@export var staff_schedule_container: VBoxContainer
@export var site_selector: OptionButton


var displayed_site: Schedule.Site

var displayed_clients: Array[PersonScheduleEntry]
var displayed_therapists: Array[TherapistEntry]


func _ready() -> void:
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

	if selected_site == -1:
		for client: Client in CaseloadData.active_clients.values():
			var new_entry: PersonScheduleEntry = client_entry_scene.instantiate()
			client_schedule_container.add_child(new_entry)
			new_entry.set_up_for_client(client)
			new_entry.assignment_changed.connect(_update_therapist_display)
			displayed_clients.append(new_entry)
	else:
		for client: Client in CaseloadData.active_clients.values():
			if client.scheduled_site != selected_site:
				continue
			else:
				var new_entry: PersonScheduleEntry = client_entry_scene.instantiate()
				client_schedule_container.add_child(new_entry)
				new_entry.set_up_for_client(client)
				new_entry.assignment_changed.connect(_update_affected_displays)
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
		displayed_therapists.append(new_entry)


func _update_affected_displays(affected_therapists: Array[Therapist]) -> void:
	_update_therapist_display(affected_therapists)


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
