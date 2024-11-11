class_name PersonScheduleEntry
extends HBoxContainer

signal assignment_changed(therapists_affected: Array[Therapist])

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

var all_selectors: Array[OptionButton]

var client: Client
var data_updated: bool = false


func _ready() -> void:
	all_selectors = [mon_am_selector, mon_pm_selector, tues_am_selector, tues_pm_selector, wed_am_selector, wed_pm_selector,
	thurs_am_selector, thurs_pm_selector, fri_am_selector, fri_pm_selector]

	for selector: OptionButton in all_selectors:
		selector.add_item("No Therapist")
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


func set_up_for_client(new_client: Client, therapist_list: Array[Therapist]) -> void:
	client = new_client
	client.data_changed.connect(set_data_change_flag)
	name_label.set_text(client.client_name)

	for thx: Therapist in therapist_list:
		for selector: OptionButton in all_selectors:
			var block: Schedule.Block = selector.get_meta(block_name)
			if thx.work_schedule.has(block) and thx.work_schedule[block] == client.scheduled_site:
				selector.add_item(thx.therapist_name)
				var item_index: int = selector.item_count - 1
				selector.set_item_metadata(item_index, thx)

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

	for block: Schedule.Block in client.unfilled_slots:
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
		assignment_changed.emit(impacted_therapists)
		return

	var new_therapist: Therapist = selector.get_selected_metadata()
	var impacted_client: Client = new_therapist.get_scheduled_client(block)
	if impacted_client != null:
		impacted_client.clear_block(block)

	client.update_assigned_therapist(block, new_therapist)
	if client.assigned_therapists.keys().has(block):
		selector.theme_type_variation = "filled"
	impacted_therapists.append(new_therapist)

	assignment_changed.emit(impacted_therapists)


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
			if selector.get_selected_metadata() == thx:
				continue
			else:
				for index: int in selector.item_count:
					if selector.get_item_metadata(index) == thx:
						selector.select(index)
						selector.item_selected.emit(index)
						continue
		else:
			if selector.selected == 0:
				continue
			else:
				selector.select(0)
				selector.item_selected.emit(0)
