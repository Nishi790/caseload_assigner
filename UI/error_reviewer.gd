class_name ErrorReviewer
extends PanelContainer


@export var client_site_error_container: FlowContainer
@export var staff_site_error_container: FlowContainer
@export var client_site_error_scene: PackedScene
@export var staff_site_error_scene: PackedScene
@export var confirm_button: Button

var tab_id: int

var clients_with_site_errors: Array[Client]
var staff_with_site_errors: Array[Dictionary] #Thx:block

var pending_client_changes: Dictionary #Client: Site
var pending_therapist_changes: Dictionary #Therapist: {block: site}

func _ready():
	confirm_button.pressed.connect(confirm_changes)
	set_up_display()


func _on_return_to_tab(id: int) -> void:
	if id == tab_id:
		set_up_display()


func set_up_display() -> void:
	clients_with_site_errors.clear()
	staff_with_site_errors.clear()
	pending_client_changes.clear()
	pending_therapist_changes.clear()

	_review_clients_for_site_errors()
	_review_staff_for_site_errors()
	_display_client_errors()
	_display_therapist_errors()


func _review_clients_for_site_errors() -> void:
	for client: Client in CaseloadData.active_clients.values():
		if client.scheduled_site == Schedule.Site.ALL_SITES and not clients_with_site_errors.has(client):
			clients_with_site_errors.append(client)


func _review_staff_for_site_errors() -> void:
	for employee: Therapist in CaseloadData.active_staff.values():
		for block: Schedule.Block in employee.work_schedule:
			if employee.work_schedule[block] == Schedule.Site.ALL_SITES:
				var staff_dict: Dictionary = {employee: block}
				if not staff_with_site_errors.has(staff_dict):
					staff_with_site_errors.append(staff_dict)


func _display_client_errors() -> void:
	for client: Client in clients_with_site_errors:
		var display: ClientSiteError = client_site_error_scene.instantiate()
		client_site_error_container.add_child(display)
		display.set_up(client)
		display.site_selected.connect(_add_client_site_change.bind(client))


func _display_therapist_errors() -> void:
	for error_dict: Dictionary in staff_with_site_errors:
		var display: StaffSiteError = staff_site_error_scene.instantiate()
		staff_site_error_container.add_child(display)
		var therapist: Therapist = error_dict.keys()[0]
		var block: Schedule.Block = error_dict[therapist]
		display.set_up(therapist, block)
		display.site_selected.connect(_add_therapist_site_change.bind(therapist, block))


func _add_client_site_change(site: Schedule.Site, client: Client) -> void:
	pending_client_changes[client] = site


func _add_therapist_site_change(site: Schedule.Site, thx: Therapist, block: Schedule.Block) -> void:
	if pending_therapist_changes.has(thx):
		var thx_changes: Dictionary = pending_therapist_changes[thx]
		thx_changes[block] = site
	else:
		pending_therapist_changes[thx] = {block: site}


func confirm_changes() -> void:
	for changed_client: Client in pending_client_changes:
		changed_client.scheduled_site = pending_client_changes[changed_client]

	for changed_thx: Therapist in pending_therapist_changes:
		var change_data: Dictionary = pending_therapist_changes[changed_thx]
		for block: Schedule.Block in change_data:
			var site: Schedule.Site = change_data[block]
			changed_thx.work_schedule[block] = site

	for entry: Control in client_site_error_container.get_children():
		entry.queue_free()
	for entry: Control in staff_site_error_container.get_children():
		entry.queue_free()

	set_up_display()
