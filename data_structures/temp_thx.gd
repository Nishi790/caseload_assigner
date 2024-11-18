class_name TempTherapist
extends Resource

var name: String
var id: int
var scheduled_visits: Dictionary
var scheduled_admin: Dictionary #block: site
var type: Therapist.Type = Therapist.Type.IT


func _init(data_dict: Dictionary) -> void:
	id = data_dict.keys()[0].to_int()
	name = data_dict.values()[0]


func add_block(block: Schedule.Block, client: Client) -> void:
	scheduled_visits[block] = client


func remove_block(block: Schedule.Block) -> void:
	scheduled_visits.erase(block)


func add_admin(block: Schedule.Block, site: Schedule.Site) -> void:
	scheduled_admin[block] = site


func create_thx() -> Therapist:
	var existing_thx: Therapist
	if CaseloadData.active_staff.has(id):
		existing_thx = CaseloadData.active_staff[id]
	var thx: Therapist = Therapist.new()
	thx.AC_id = id
	thx.therapist_name = name
	thx.therapist_type = type
	for block: Schedule.Block in scheduled_admin:
		var scheduled_site: Schedule.Site = scheduled_admin[block]
		if scheduled_site == Schedule.Site.ALL_SITES:
			scheduled_site = find_corresponding_site(block, thx)
			if scheduled_site == Schedule.Site.ALL_SITES and existing_thx != null:
				if existing_thx.work_schedule.has(block):
					scheduled_site = existing_thx.work_schedule[block]
		thx.add_work_block_to_schedule(block, scheduled_site)
		thx.admin_blocks.append(block)

	for block: Schedule.Block in scheduled_visits:
		var scheduled_client: Client = scheduled_visits[block]
		var visit_site: Schedule.Site = scheduled_client.scheduled_site
		if visit_site == Schedule.Site.ALL_SITES:
			visit_site = find_corresponding_site(block, thx)
			if visit_site == Schedule.Site.ALL_SITES and existing_thx != null:
				if existing_thx.work_schedule.has(block):
					visit_site = existing_thx.work_schedule[block]
		thx.add_work_block_to_schedule(block, visit_site)
		thx.scheduled_blocks[block] = scheduled_client.AC_id

	if not thx.work_schedule.values().has(Schedule.Site.ALL_SITES):
		return thx

	var all_site_blocks: Array[Schedule.Block]
	var totals: Dictionary = {Schedule.Site.COLONNADE: 0, Schedule.Site.LANCASTER: 0, Schedule.Site.KANATA: 0,
	Schedule.Site.PEMBROKE: 0}

	for block: Schedule.Block in thx.work_schedule:
		var site: Schedule.Site = thx.work_schedule[block]
		if totals.has(site):
			totals[site] = totals[site] + 1
		else:
			all_site_blocks.append(block)
	var most_frequent_site: Schedule.Site = get_most_frequent_site(totals)
	for block: Schedule.Block in all_site_blocks:
		thx.work_schedule[block] = most_frequent_site

	return thx


func find_corresponding_site(block: Schedule.Block, therapist: Therapist) -> Schedule.Site:
	var corresponding_block: Schedule.Block
	match block:
		Schedule.Block.MONDAY_AM:
			corresponding_block = Schedule.Block.MONDAY_PM
		Schedule.Block.MONDAY_PM:
			corresponding_block = Schedule.Block.MONDAY_AM
		Schedule.Block.TUESDAY_AM:
			corresponding_block = Schedule.Block.TUESDAY_PM
		Schedule.Block.TUESDAY_PM:
			corresponding_block = Schedule.Block.TUESDAY_AM
		Schedule.Block.WEDNESDAY_AM:
			corresponding_block = Schedule.Block.WEDNESDAY_PM
		Schedule.Block.WEDNESDAY_PM:
			corresponding_block = Schedule.Block.WEDNESDAY_AM
		Schedule.Block.THURSDAY_AM:
			corresponding_block = Schedule.Block.THURSDAY_PM
		Schedule.Block.THURSDAY_PM:
			corresponding_block = Schedule.Block.THURSDAY_AM
		Schedule.Block.FRIDAY_AM:
			corresponding_block = Schedule.Block.FRIDAY_PM
		Schedule.Block.FRIDAY_PM:
			corresponding_block = Schedule.Block.FRIDAY_AM

	if scheduled_admin.has(corresponding_block):
		return scheduled_admin[corresponding_block]
	elif therapist.work_schedule.has(corresponding_block):
		return therapist.work_schedule[corresponding_block]
	else:
		return Schedule.Site.ALL_SITES


func get_most_frequent_site(totals: Dictionary) -> Schedule.Site:
	var max_site: Schedule.Site = Schedule.Site.ALL_SITES
	var max_value: int = 0
	for key: Schedule.Site in totals:
		var value: int = totals[key]
		if value > max_value:
			max_site = key
			max_value = value
	return max_site
