class_name ACDataImporter
extends Resource

signal changes_to_confirm(clients: Array[Client])

const client_id_key: String = "Client ID"
const client_name_key: String = "Client Full Name"
const employee_id_key: String = "Employee ID"
const employee_name_key: String = "Employee Full Name"
const visit_day_key: String = "Visit Start Day of Week"
const visit_hour_key: String = "Visit Start Hour of Day"
const facility_key: String = "Facility Name"
const service_code_key: String = "Service Code Name"


var json_object: JSON = JSON.new()

var parsed_clients: Dictionary #id: Client
var parsed_employees: Dictionary #id: TempThx

var client_changes_to_confirm: Array[Client]
var therapists_to_add: Array[TempTherapist]


func load_data(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Can't locate file at path %s" % path)
		return

	var file_access: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json_content: String = file_access.get_as_text()

	json_object.parse(json_content)
	_parse_clients()


func _parse_clients() -> void:
	var clients: Dictionary = {}
	var current_client_array: Array[Dictionary] = []
	var current_client_id: String = ""
	for entry: Dictionary in json_object.data:
		if entry[client_id_key] == current_client_id:
			current_client_array.append(entry)
		else:
			if current_client_id != "":
				clients[current_client_id] = current_client_array
				current_client_array = []
			current_client_id = entry[client_id_key]
			current_client_array.append(entry)

	clients[current_client_id] = current_client_array

	for client_array: Array[Dictionary] in clients.values():
		if client_array[0][client_id_key].to_int() == 378024:
			print("Matched admin client")
			_create_admin_blocks(client_array)
		else:
			_create_client(client_array)

	_compare_existing_clients()

	changes_to_confirm.emit(client_changes_to_confirm)



func _create_client(client_data: Array[Dictionary]) -> void:
	var client = Client.new()
	client.AC_id = client_data[0][client_id_key].to_int()
	client.client_name = client_data[0][client_name_key]

	var visit_blocks: Array[Schedule.Block] = []
	var visit_thxs: Array[Dictionary]
	var site_count_dict: Dictionary = {Schedule.Site.COLONNADE: 0, Schedule.Site.LANCASTER: 0,
		Schedule.Site.KANATA: 0, Schedule.Site.PEMBROKE: 0, Schedule.Site.ALL_SITES: 0}

	for visit_data: Dictionary in client_data:
		var is_valid_visit: bool = check_valid_visit(visit_data[service_code_key])
		if is_valid_visit:
			var in_morning: bool = false
			if visit_data[visit_hour_key].to_int() < 12:
				in_morning = true
			var block: Schedule.Block = get_visit_block(visit_data[visit_day_key], in_morning)
			visit_blocks.append(block)

			var visit_site = visit_data[facility_key]
			var site: Schedule.Site
			if visit_site != null:
				site = get_service_site(visit_data[facility_key])
			else:
				site = Schedule.Site.ALL_SITES
			site_count_dict[site] += 1

			var visit_thx: Dictionary = {visit_data[employee_id_key]: visit_data[employee_name_key]}
			visit_thxs.append(visit_thx)

	client.scheduled_site = get_most_frequent_site(site_count_dict)
	client.scheduled_blocks = visit_blocks
	for index: int in visit_thxs.size():
		var thx_dict: Dictionary = visit_thxs[index]
		var thx_id: int = thx_dict.keys()[0].to_int()

		if parsed_employees.has(thx_id):
			var temp_thx: TempTherapist = parsed_employees[thx_id]
			temp_thx.add_block(client.scheduled_blocks[index], client)
		else:
			var temp_thx: TempTherapist = TempTherapist.new(thx_dict)
			temp_thx.add_block(client.scheduled_blocks[index], client)
			parsed_employees[temp_thx.id] = temp_thx
		client.assigned_therapists[client.scheduled_blocks[index]] = parsed_employees[thx_id]

	client.scheduled_blocks.assign(Utilities.array_remove_duplicates(client.scheduled_blocks))
	parsed_clients[client.AC_id] = client


func _create_admin_blocks(visit_data: Array[Dictionary]) -> void:
	for data: Dictionary in visit_data:
		var therapist: TempTherapist
		var thx_id: int = data[employee_id_key].to_int()
		if parsed_employees.has(thx_id):
			therapist = parsed_employees[thx_id]
		else:
			therapist = TempTherapist.new({data[employee_id_key]: data[employee_name_key]})
			parsed_employees[thx_id] = therapist

		var thx_is_lead: bool = check_admin_visit_type(data[service_code_key])
		if thx_is_lead:
			therapist.type = Therapist.Type.LEAD
		else:
			therapist.type = Therapist.Type.IT

		var in_morning: bool = false
		if data[visit_hour_key].to_int() < 12:
			in_morning = true

		var block: Schedule.Block = get_visit_block(data[visit_day_key], in_morning)
		var site: Schedule.Site

		if data[facility_key] == null:
			site = Schedule.Site.ALL_SITES
		else:
			site = get_service_site(data[facility_key])

		therapist.add_admin(block, site)


func _compare_existing_clients() -> void:
	for id: int in parsed_clients:
		if CaseloadData.active_clients.has(id):
			var parsed_client: Client = parsed_clients[id]
			var existing_client: Client = CaseloadData.active_clients[id]
			if not _is_client_same(parsed_client, existing_client):
				client_changes_to_confirm.append(parsed_client)
		else:
			CaseloadData.active_clients[id] = parsed_clients[id]


func _is_client_same(parsed_client: Client, existing_client: Client) -> bool:
	var same_schedule: bool = false
	var same_therapists: bool = true
	var same_site: bool = false

	parsed_client.scheduled_blocks.sort()
	existing_client.scheduled_blocks.sort()
	if parsed_client.scheduled_blocks == existing_client.scheduled_blocks:
		same_schedule = true
	if parsed_client.scheduled_site == existing_client.scheduled_site:
		same_site = true
	for block: Schedule.Block in parsed_client.assigned_therapists:
		var parsed_thx = parsed_client.assigned_therapists[block]
		if existing_client.assigned_therapists.has(block) == false:
			same_therapists = false
			break
		if parsed_thx is Therapist:
			if existing_client.assigned_therapists[block] != parsed_thx:
				same_therapists = false
				break
		elif parsed_thx is TempTherapist:
			if existing_client.assigned_therapists[block].AC_id != parsed_thx.id:
				same_therapists = false
				break
		elif parsed_thx.type == TYPE_INT:
			if existing_client.assigned_therapists[block].AC_id != parsed_thx:
				same_therapists = false
				break
	if same_schedule and same_site and same_therapists:
		return true
	else:
		return false


func connect_therapists() -> void:
	for temp_thx: TempTherapist in parsed_employees.values():
		var imported_therapist: Therapist
		if CaseloadData.active_staff.has(temp_thx.id):
			var existing_thx: Therapist = CaseloadData.active_staff[temp_thx.id]
			var same: bool = _is_thx_same(temp_thx, existing_thx)
			if same:
				continue

		imported_therapist = temp_thx.create_thx()
		CaseloadData.active_staff[imported_therapist.AC_id] = imported_therapist
		imported_therapist.connect_clients_by_id()

	CaseloadData.clean_client_entries()


func _is_thx_same(new_thx: TempTherapist, existing_thx: Therapist) -> bool:
	var same_scheduled_visits: bool = true
	var same_clients: bool = true
	var same_block_sites: bool = true
	var same_admin: bool = true

	for block: Schedule.Block in new_thx.scheduled_visits:
		if not existing_thx.scheduled_blocks.has(block):
			same_scheduled_visits = false
			break
		if existing_thx.scheduled_blocks[block].AC_id != new_thx.scheduled_visits[block].AC_id:
			same_clients = false
			break
		var visit_site: Schedule.Site = new_thx.scheduled_visits[block].scheduled_site
		if existing_thx.work_schedule[block] != visit_site:
			same_block_sites = false
			break

	for block: Schedule.Block in new_thx.scheduled_admin:
		if not existing_thx.admin_blocks.has(block):
			same_admin = false
			break

	if same_scheduled_visits and same_clients and same_block_sites and same_admin:
		return true

	return false


func check_valid_visit(service_code: String) -> bool:
	var valid: bool = false

	if service_code.containsn("ABA Therapy Monthly") or service_code.containsn("ESDM Therapy Monthly"):
		valid = true

	return valid


func check_admin_visit_type(service_code: String) -> bool:
	if service_code.containsn("lead"):
		return true
	else:
		return false


func get_visit_block(day: String, in_morning: bool) -> Schedule.Block:
	var block: Schedule.Block
	match day:
		"Monday" when in_morning == true:
			block = Schedule.Block.MONDAY_AM
		"Monday":
			block = Schedule.Block.MONDAY_PM
		"Tuesday" when in_morning == true:
			block = Schedule.Block.TUESDAY_AM
		"Tuesday":
			block = Schedule.Block.TUESDAY_PM
		"Wednesday" when in_morning == true:
			block = Schedule.Block.WEDNESDAY_AM
		"Wednesday":
			block = Schedule.Block.WEDNESDAY_PM
		"Thursday" when in_morning == true:
			block = Schedule.Block.THURSDAY_AM
		"Thursday":
			block = Schedule.Block.THURSDAY_PM
		"Friday" when in_morning == true:
			block = Schedule.Block.FRIDAY_AM
		"Friday":
			block = Schedule.Block.FRIDAY_PM
	return block


func get_service_site(site_name: String) -> Schedule.Site:
	var site: Schedule.Site
	if site_name.containsn("Colonnade"):
		site = Schedule.Site.COLONNADE
	elif site_name.containsn("Lancaster"):
		site = Schedule.Site.LANCASTER
	elif site_name.containsn("Kanata"):
		site = Schedule.Site.KANATA
	elif site_name.containsn("Pembroke"):
		site = Schedule.Site.PEMBROKE
	else:
		site = Schedule.Site.ALL_SITES
	return site


func get_most_frequent_site(dict: Dictionary) -> Schedule.Site:
	var max_value: int = -999
	for key: Schedule.Site in dict:
		if dict[key] > max_value:
			max_value = dict[key]

	var most_freq_site: Schedule.Site = dict.find_key(max_value)
	return most_freq_site
