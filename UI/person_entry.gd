class_name PersonScheduleEntry
extends HBoxContainer

signal assignment_changed(therapists_affected: Array[Therapist], block: Schedule.Block)

const block_name: StringName = &"Block"

@export var name_label: Label

@export var mon_am_selector: OptionButton
@export var tues_am_selector: OptionButton
@export var wed_am_selector: OptionButton
@export var thurs_am_selector: OptionButton
@export var fri_am_selector: OptionButton

@export var mon_pm_selector: OptionButton
@export var tues_pm_selector: OptionButton
@export var wed_pm_selector: OptionButton
@export var thurs_pm_selector: OptionButton
@export var fri_pm_selector: OptionButton

@export var delete_button: Button

var all_selectors: Array[OptionButton]

var client: Client
var data_updated: bool = false


func _ready() -> void:
	all_selectors = [mon_am_selector, mon_pm_selector, tues_am_selector, tues_pm_selector, wed_am_selector, wed_pm_selector,
	thurs_am_selector, thurs_pm_selector, fri_am_selector, fri_pm_selector]

	for selector: OptionButton in all_selectors:
		selector.add_item("")
		selector.select(0)
		selector.tooltip_text = "No Therapist"
		selector.set_item_metadata(0, null)
		selector.item_selected.connect(change_assignment.bind(selector))


	mon_am_selector.set_meta(block_name, Schedule.Block.MONDAY_AM)
	mon_pm_selector.set_meta(block_name, Schedule.Block.MONDAY_PM)
	tues_am_selector.set_meta(block_name, Schedule.Block.TUESDAY_AM)
	tues_pm_selector.set_meta(block_name, Schedule.Block.TUESDAY_PM)
	wed_am_selector.set_meta(block_name, Schedule.Block.WEDNESDAY_AM)
	wed_pm_selector.set_meta(block_name, Schedule.Block.WEDNESDAY_PM)
	thurs_am_selector.set_meta(block_name, Schedule.Block.THURSDAY_AM)
	thurs_pm_selector.set_meta(block_name, Schedule.Block.THURSDAY_PM)
	fri_am_selector.set_meta(block_name, Schedule.Block.FRIDAY_AM)
	fri_pm_selector.set_meta(block_name, Schedule.Block.FRIDAY_PM)


func _process(_delta: float) -> void:
	if data_updated:
		data_updated = false
		update_assigned_therapists()


func set_up_for_client(new_client: Client) -> void:
	client = new_client
	client.data_changed.connect(set_data_change_flag)
	name_label.set_text(client.client_name)

	for block: Schedule.Block in Schedule.Block.values():
		_sort_therapist_selector(block)
		if not client.scheduled_blocks.has(block):
			var selector: OptionButton = find_block_selector(block)
			selector.disabled = true

	for entry in client.assigned_therapists:
		var therapist = client.assigned_therapists[entry]
		var selector: OptionButton = find_block_selector(entry)
		for item_index: int in selector.get_item_count():
			var selector_therapist: Therapist = selector.get_item_metadata(item_index)
			if selector_therapist == therapist:
				selector.selected = item_index
				selector.theme_type_variation = "filled"
				selector.tooltip_text = selector.get_item_text(item_index)
				break

	for block: Schedule.Block in client.scheduled_blocks:
		if not client.assigned_therapists.has(block):
			var selector: OptionButton = find_block_selector(block)
			selector.theme_type_variation = "unfilled"



func change_assignment(selected_index: int, selector: OptionButton) -> void:
	selector.tooltip_text = selector.get_item_text(selected_index)

	var impacted_therapists: Array[Therapist] = []
	var block: Schedule.Block = selector.get_meta(block_name)
	var current_thx: Therapist
	if client.assigned_therapists.has(block):
		current_thx = client.assigned_therapists[block]
		impacted_therapists.append(current_thx)

	if selector.get_selected_metadata() == null:
		client.clear_block(block)
		if current_thx != null:
			current_thx.free_slot(block)
		if client.unfilled_slots.has(block):
			selector.theme_type_variation = "unfilled"
		else:
			selector.theme_type_variation = ""
		assignment_changed.emit(impacted_therapists, block)
		return

	var new_therapist: Therapist = selector.get_selected_metadata()
	var impacted_client: Client = new_therapist.get_scheduled_client(block)
	if impacted_client != null:
		impacted_client.clear_block(block)

	client.update_assigned_therapist(block, new_therapist)
	if client.assigned_therapists.keys().has(block):
		selector.theme_type_variation = "filled"
	impacted_therapists.append(new_therapist)

	assignment_changed.emit(impacted_therapists, block)


func resort_all_thx_selectors() -> void:
	for block: Schedule.Block in Schedule.Block:
		resort_thx_selector(block)


func resort_thx_selector(block: Schedule.Block) -> void:
	var selector: OptionButton = find_block_selector(block)
	var thx_list: Array[Therapist]
	for index: int in selector.item_count:
		if selector.is_item_separator(index) or selector.get_item_text(index) == "":
			continue
		var thx: Therapist = selector.get_item_metadata(index)
		thx_list.append(thx)
	_sort_therapist_selector(block, thx_list)


func find_block_selector(block: Schedule.Block) -> OptionButton:
	for selector: OptionButton in all_selectors:
		if selector.get_meta(block_name) == block:
			return selector
	printerr("Failed to locate an option button for %s at %s. Check scene set-up" % [Schedule.get_block_string(block), get_stack()])
	return null


func set_data_change_flag(_client: Client) -> void:
	data_updated = true


func update_assigned_therapists() -> void:
	for selector: OptionButton in all_selectors:
		var target_block: Schedule.Block = selector.get_meta(block_name)
		if client.assigned_therapists.has(target_block):
			var thx: Therapist = client.assigned_therapists[target_block]
			_select_therapist(selector, thx)
		else:
			selector.tooltip_text = "No Therapist"
			if selector.selected == 0:
				if client.unfilled_slots.has(target_block):
					selector.theme_type_variation = "unfilled"
				else:
					continue
			else:
				selector.select(0)
				selector.item_selected.emit(0)


func _select_therapist(selector: OptionButton, thx: Therapist) -> void:
	if selector.get_selected_metadata() == thx:
		return
	else:
		for index: int in selector.item_count:
			if selector.get_item_metadata(index) == thx:
				selector.select(index)
				selector.item_selected.emit(index)
				return


func _sort_therapist_selector(block: Schedule.Block, thx_array: Array = CaseloadData.active_staff.values()) -> void:
	var avail_thx_array: Array[Therapist]
	var booked_thx_array: Array[Therapist]
	var selected_therapist: Therapist = null
	if client.assigned_therapists.has(block):
		selected_therapist = client.assigned_therapists[block]
	for thx: Therapist in thx_array:
		if thx.admin_blocks.has(block) and thx.work_schedule[block] == client.scheduled_site:
			avail_thx_array.append(thx)
		elif thx.scheduled_blocks.has(block) and thx.work_schedule[block] == client.scheduled_site:
			booked_thx_array.append(thx)
	var selector: OptionButton = find_block_selector(block)
	selector.clear()
	avail_thx_array.sort_custom(sort_alphabetical)
	booked_thx_array.sort_custom(sort_alphabetical)
	selector.add_item("")
	var selector_index: int = 1
	for thx: Therapist in avail_thx_array:
		selector.add_item(thx.therapist_name)
		selector.set_item_metadata(selector_index, thx)
		if thx == selected_therapist:
			selector.select(selector_index)
		selector_index += 1
	selector.add_separator("Booked")
	selector_index += 1

	for thx: Therapist in booked_thx_array:
		selector.add_item(thx.therapist_name)
		selector.set_item_metadata(selector_index, thx)
		if thx == selected_therapist:
			selector.select(selector_index)
		selector_index += 1


func sort_alphabetical(a: Therapist, b: Therapist) -> bool:
		var a_name: String = a.therapist_name
		var b_name: String = b.therapist_name
		return b_name > a_name
