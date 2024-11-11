class_name SummarySection
extends PanelContainer

signal client_changed(section: SummarySection, client: Client)

const block_name: StringName = &"block"

@export var site_label: Label

@export var avail_mon_am_label: Label
@export var avail_tues_am_label: Label
@export var avail_wed_am_label: Label
@export var avail_thurs_am_label: Label
@export var avail_fri_am_label: Label

@export var avail_mon_pm_label: Label
@export var avail_tues_pm_label: Label
@export var avail_wed_pm_label: Label
@export var avail_thurs_pm_label: Label
@export var avail_fri_pm_label: Label

@export var unfilled_container: VBoxContainer
@export var requests_container: VBoxContainer

@export var unfilled_list_scene: PackedScene
@export var request_scene: PackedScene

var mon_am_count: int = 0
var tues_am_count: int = 0
var wed_am_count: int = 0
var thurs_am_count: int = 0
var fri_am_count: int = 0

var mon_pm_count: int = 0
var tues_pm_count: int = 0
var wed_pm_count: int = 0
var thurs_pm_count: int = 0
var fri_pm_count: int = 0

var labels: Array[Label]
var unfilled_entries: Array[UnfilledClientDisplay]
var request_entries: Array[RequestedSlotDisplay]

var site: Schedule.Site

func _ready() -> void:
	labels = [avail_mon_am_label, avail_tues_am_label, avail_wed_am_label, avail_thurs_am_label, avail_fri_am_label,
	avail_mon_pm_label, avail_tues_pm_label, avail_wed_pm_label, avail_thurs_pm_label, avail_fri_pm_label]

	avail_mon_am_label.set_meta(block_name, Schedule.Block.MONDAY_AM)
	avail_tues_am_label.set_meta(block_name, Schedule.Block.TUESDAY_AM)
	avail_wed_am_label.set_meta(block_name, Schedule.Block.WEDNESDAY_AM)
	avail_thurs_am_label.set_meta(block_name, Schedule.Block.THURSDAY_AM)
	avail_fri_am_label.set_meta(block_name, Schedule.Block.FRIDAY_AM)

	avail_mon_pm_label.set_meta(block_name, Schedule.Block.MONDAY_PM)
	avail_tues_pm_label.set_meta(block_name, Schedule.Block.TUESDAY_PM)
	avail_wed_pm_label.set_meta(block_name, Schedule.Block.WEDNESDAY_PM)
	avail_thurs_pm_label.set_meta(block_name, Schedule.Block.THURSDAY_PM)
	avail_fri_pm_label.set_meta(block_name, Schedule.Block.FRIDAY_PM)


func set_site(new_site: Schedule.Site) -> void:
	site = new_site
	var current_style_box: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	current_style_box.border_color = CaseloadData.get_site_colour(site)
	current_style_box.set_border_width_all(3)
	current_style_box.set_corner_radius_all(4)
	current_style_box.set_content_margin_all(6)
	add_theme_stylebox_override("panel", current_style_box)
	site_label.set_text(Schedule.get_site_string(site))
	display_totals()
	display_unfilled_slots()
	display_requests()


func display_totals() -> void:
	CaseloadData.alphabetize_lists()
	for thx: Therapist in CaseloadData.alphabetical_staff:
		for block: Schedule.Block in thx.admin_blocks:
			if site != Schedule.Site.ALL_SITES and thx.work_schedule[block] == site:
				increment_block_count(block)
			elif site == Schedule.Site.ALL_SITES:
				increment_block_count(block)
			else:
				continue

	_set_summary_labels()


func display_unfilled_slots() -> void:
	var clients_to_display: Array[Client] = []
	for client: Client in CaseloadData.active_clients.values():
		if not client.unfilled_slots.is_empty() and (site == Schedule.Site.ALL_SITES or client.scheduled_site == site):
			clients_to_display.append(client)

	clients_to_display.sort_custom(func alphabetize(a: Client, b: Client) -> bool:
		return a.client_name < b.client_name)

	var use_darker_panel: bool = false
	for client: Client in clients_to_display:
		create_unfilled_display(client, use_darker_panel)
		use_darker_panel = not use_darker_panel


func display_requests() -> void:
	var client_requests: Array[Client] = []
	for client: Client in CaseloadData.active_clients.values():
		if not client.requested_blocks.is_empty() and (site == Schedule.Site.ALL_SITES or client.requested_site == site):
			client_requests.append(client)

	client_requests.sort_custom(func alphabetize(a: Client, b: Client) -> bool:
		return a.client_name < b.client_name)

	var use_darker_panel: bool = false
	for client: Client in client_requests:
		create_request_display(client, use_darker_panel)
		use_darker_panel = not use_darker_panel


func move_request_to_unfilled(request_display: RequestedSlotDisplay) -> void:
	request_display.queue_free()
	request_entries.erase(request_display)
	var first_dark: bool = false
	if requests_container.get_child(1).theme_type_variation == "darker_panel":
		first_dark = true
	propagate_color_change(0, requests_container, first_dark)

	var affected_client: Client = request_display.client

	var display_to_erase: UnfilledClientDisplay
	var index_for_new: int = -1
	var dark: bool = false

	var unfilled_name_array: Array[String] = []
	var index: int = 0
	for display: Control in unfilled_container.get_children():
		if display is not UnfilledClientDisplay:
			index += 1
			continue
		if display.client == affected_client:
			display_to_erase = display
			index_for_new = index
			if display.theme_type_variation == "darker_panel":
				dark = true
			break
		unfilled_name_array.append(display.client.client_name)
		index += 1

	if display_to_erase != null:
		unfilled_entries.erase(display_to_erase)
		display_to_erase.queue_free()
		create_unfilled_display(affected_client, dark, index_for_new)

	else:
		var index_to_insert = Utilities.find_alphabetical_insertion_index(affected_client.client_name, unfilled_name_array)
		if index_to_insert == -1:
			var child_count: int = unfilled_container.get_child_count()
			if child_count > 1:
				var last_child: Node = unfilled_container.get_child(unfilled_container.get_child_count() - 1)
				if last_child.theme_type_variation == "darker_panel":
					dark = false
				else:
					dark = true
			else:
				dark = true
			create_unfilled_display(affected_client, dark)
		else:
			if unfilled_container.get_child(index_to_insert).theme_type_variation == "darker_panel":
				dark = false
			else: dark = true
			create_unfilled_display(affected_client, dark, index_to_insert + 1)
			propagate_color_change(index_to_insert + 1, unfilled_container, not dark)
	client_changed.emit(self, affected_client)


func refresh_display() -> void:
	mon_am_count = 0
	tues_am_count = 0
	wed_am_count = 0
	thurs_am_count = 0
	fri_am_count = 0
	mon_pm_count = 0
	tues_pm_count = 0
	wed_pm_count = 0
	thurs_pm_count = 0
	fri_pm_count = 0

	for entry: UnfilledClientDisplay in unfilled_entries:
		entry.queue_free()
	unfilled_entries.clear()
	for entry: RequestedSlotDisplay in request_entries:
		entry.queue_free()
	request_entries.clear()

	display_totals()
	display_unfilled_slots()
	display_requests()


func refresh_client(client: Client) -> void:
	var unfilled_name_array: Array[String] = []
	var requested_name_array: Array[String] = []

	for unfilled: Control in unfilled_container.get_children():
		if unfilled is not UnfilledClientDisplay:
			continue
		if unfilled.client == client:
			unfilled_entries.erase(unfilled)
			unfilled.queue_free()
			continue
		unfilled_name_array.append(unfilled.client.client_name)

	for display: Control in requests_container.get_children():
		if display is not RequestedSlotDisplay:
			continue
		if display.client == client:
			request_entries.erase(display)
			display.queue_free()
			continue
		requested_name_array.append(display.client.client_name)

	if (client.scheduled_site == site or site == Schedule.Site.ALL_SITES) and not client.unfilled_slots.is_empty():
		var previous_type_variation: String
		var unfilled_index: int = Utilities.find_alphabetical_insertion_index(client.client_name, unfilled_name_array)
		if unfilled_index != -1:
			unfilled_index += 1 #to account for title taking up index 0
			previous_type_variation = unfilled_container.get_child(unfilled_index - 1).get_theme_type_variation()
		else:
			if unfilled_container.get_child_count() > 1:
				previous_type_variation = unfilled_container.get_child(unfilled_container.get_child_count() - 1).theme_type_variation
			else:
				previous_type_variation = "lighter_panel"
		var dark: bool
		if previous_type_variation == "darker_panel":
			dark = false
		else:
			dark = true
		create_unfilled_display(client, dark, unfilled_index)
		propagate_color_change(unfilled_index, unfilled_container, not dark)

	if (client.requested_site == site or site == Schedule.Site.ALL_SITES) and not client.requested_blocks.is_empty():
		var previous_type_variation: String
		var requested_index: int = Utilities.find_alphabetical_insertion_index(client.client_name, requested_name_array)
		if requested_index != -1:
			requested_index += 1
			previous_type_variation = requests_container.get_child(requested_index - 1).get_theme_type_variation()
		else:
			var child_count: int = requests_container.get_child_count()
			if child_count > 1:
				previous_type_variation = requests_container.get_child(child_count - 1).theme_type_variation
			else:
				previous_type_variation = "lighter_panel"

		var dark: bool
		if previous_type_variation == "darker_panel":
			dark = false
		else: dark = true
		create_request_display(client, dark, requested_index)
		propagate_color_change(requested_index, requests_container, not dark)


func create_unfilled_display(client: Client, dark: bool = true, position_index: int = -1) -> void:
	var unfilled_display: UnfilledClientDisplay = unfilled_list_scene.instantiate()

	if dark:
		unfilled_display.theme_type_variation = "darker_panel"
	else:
		unfilled_display.theme_type_variation = "lighter_panel"

	unfilled_display.initiate_display(client)
	unfilled_container.add_child(unfilled_display)
	if position_index != -1:
		unfilled_container.move_child(unfilled_display, position_index)
	unfilled_entries.append(unfilled_display)


func create_request_display(client: Client, dark: bool = true, position_index: int = -1) -> void:
	var open_request_display: RequestedSlotDisplay = request_scene.instantiate()

	if dark:
		open_request_display.theme_type_variation = "darker_panel"
	else:
		open_request_display.theme_type_variation = "lighter_panel"

	open_request_display.initiate_display(client)
	requests_container.add_child(open_request_display)
	if position_index != -1:
		requests_container.move_child(open_request_display, position_index)
	request_entries.append(open_request_display)
	open_request_display.request_accepted.connect(move_request_to_unfilled)


func _set_summary_labels() -> void:
	avail_mon_am_label.set_text(str(mon_am_count))
	avail_mon_pm_label.set_text(str(mon_pm_count))

	avail_tues_am_label.set_text(str(tues_am_count))
	avail_tues_pm_label.set_text(str(tues_pm_count))

	avail_wed_am_label.set_text(str(wed_am_count))
	avail_wed_pm_label.set_text(str(wed_pm_count))

	avail_thurs_am_label.set_text(str(thurs_am_count))
	avail_thurs_pm_label.set_text(str(thurs_pm_count))

	avail_fri_am_label.set_text(str(fri_am_count))
	avail_fri_pm_label.set_text(str(fri_pm_count))


func increment_block_count(block: Schedule.Block) -> void:
	match block:
		Schedule.Block.MONDAY_AM:
			mon_am_count += 1
		Schedule.Block.MONDAY_PM:
			mon_pm_count += 1
		Schedule.Block.TUESDAY_AM:
			tues_am_count += 1
		Schedule.Block.TUESDAY_PM:
			tues_pm_count += 1
		Schedule.Block.WEDNESDAY_AM:
			wed_am_count += 1
		Schedule.Block.WEDNESDAY_PM:
			wed_pm_count += 1
		Schedule.Block.THURSDAY_AM:
			thurs_am_count += 1
		Schedule.Block.THURSDAY_PM:
			thurs_pm_count += 1
		Schedule.Block.FRIDAY_AM:
			fri_am_count += 1
		Schedule.Block.FRIDAY_PM:
			fri_pm_count += 1


func propagate_color_change(index: int, container: Container, first_one_dark: bool) -> void:
	var dark: bool = first_one_dark
	for container_index: int in container.get_child_count():
		if container_index <= index:
			continue
		else:
			var control_to_edit: Control = container.get_child(container_index)
			if control_to_edit.is_queued_for_deletion():
				continue

			if dark:
				control_to_edit.theme_type_variation = "darker_panel"
			else:
				control_to_edit.theme_type_variation = "lighter_panel"
			dark = not dark
