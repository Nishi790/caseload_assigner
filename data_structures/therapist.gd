class_name Therapist
extends Resource

signal therapist_already_scheduled

enum Type {IT, LEAD, SBC, RBA}

@export var therapist_name: String
@export var AC_id: int
@export var work_schedule: Dictionary #Block: Site

@export var scheduled_blocks: Dictionary #Block: Client
@export var admin_blocks: Array[Schedule.Block] = []

@export var therapist_type: Type
@export var caseload: Array[Client]


static func deserialize_thx(thx_data: Dictionary) -> Therapist:
	var new_thx = Therapist.new()
	if thx_data.has("name"):
		new_thx.therapist_name = thx_data["name"]
	if thx_data.has("type"):
		new_thx.therapist_type = thx_data["type"]
	if thx_data.has("id"):
		new_thx.AC_id = int(thx_data["id"])
	if thx_data.has("scheduled_days"):
		var int_key_dict: Dictionary = Utilities.convert_string_to_int_keys(thx_data["scheduled_days"])
		new_thx.work_schedule = Utilities.convert_float_values_to_ints(int_key_dict)
	#new_thx.caseload = thx_data["caseload"]
	if thx_data.has("scheduled_clients"):
		var int_key_dict: Dictionary = Utilities.convert_string_to_int_keys(thx_data["scheduled_clients"])
		new_thx.scheduled_blocks = Utilities.convert_float_values_to_ints(int_key_dict)

	for block: Schedule.Block in new_thx.work_schedule:
		if not new_thx.scheduled_blocks.has(block):
			new_thx.admin_blocks.append(block)

	return new_thx


func connect_clients_by_id() -> void:
	for block: Schedule.Block in scheduled_blocks:
		var client_id: int = scheduled_blocks[block]
		var client_object: Client = CaseloadData.active_clients[client_id]
		scheduled_blocks[block] = client_object
		client_object.update_assigned_therapist(block, self)


func free_slot(block: Schedule.Block) -> void:
	if scheduled_blocks.has(block):
		scheduled_blocks.erase(block)
		admin_blocks.append(block)


func schedule_client(block: Schedule.Block, client: Client) -> void:
	if scheduled_blocks.has(block):
		therapist_already_scheduled.emit(scheduled_blocks[block])

	scheduled_blocks[block] = client

	if admin_blocks.has(block):
		admin_blocks.erase(block)


func add_work_block_to_schedule(block: Schedule.Block, site: Schedule.Site) -> void:
	if work_schedule.has(block):
		print_debug("Therapist is already working on %s at %s. Changing Site to %s" % [Schedule.get_block_string(block), Schedule.get_site_string(work_schedule[block]), Schedule.get_site_string(site)])

	work_schedule[block] = site
	if not admin_blocks.has(block):
		admin_blocks.append(block)


func remove_block_from_schedule(block: Schedule.Block) -> void:
	if work_schedule.has(block):
		work_schedule.erase(block)

	if admin_blocks.has(block):
		admin_blocks.erase(block)

	if scheduled_blocks.has(block):
		var affected_client: Client = scheduled_blocks[block]
		affected_client.clear_block(block)


func get_scheduled_client(block: Schedule.Block) -> Client:
	if scheduled_blocks.has(block):
		return scheduled_blocks[block]
	else: return null


func serialize_data() -> Dictionary:
	var data: Dictionary = {}

	data["name"] = therapist_name
	data["type"] = therapist_type
	data["id"] = AC_id
	data["scheduled_days"] = work_schedule

	var clients_per_block: Dictionary = {}

	for block: Schedule.Block in scheduled_blocks:
		clients_per_block[block] = scheduled_blocks[block].AC_id

	data["scheduled_clients"] = clients_per_block
	data["caseload"] = caseload

	return data
