class_name ACDataImported
extends Node

const client_id_key: String = "Client ID"
const client_name_key: String = "Client First Name"
const employee_id_key: String = "Employee ID"
const employee_name_key: String = "Employee Full Name"
const visit_day_key: String = "Visit Start Day of Week"
const visit_hour_key: String = "Visit Start Hour of Day"
const facility_key: String = "Facility Name"
const service_code_key: String = "Service Code Name"


var json_object: JSON = JSON.new()

var parsed_clients: Array
var parsed_employees: Array


func load_data(path: String) -> void:
	if not FileAccess.file_exists(path):
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

	for client_array: Array[Dictionary] in clients:
		_create_client(client_array)


func _create_client(client_data: Array[Dictionary]) -> void:
	var client = Client.new()
	client.AC_id = client_data[0][client_id_key].to_int()
	client.client_name = client_data[0][client_name_key]

	var visit_blocks: Array[Schedule.Block] = []
	var visit_sites: Array[Schedule.Site] = []

	for visit_data: Dictionary in client_data:
		var is_valid_visit: bool = check_valid_visit(visit_data[service_code_key])
		var in_morning: bool = false
		if visit_data[visit_hour_key].to_int() < 12:
			in_morning = true
		var block: Schedule.Block = get_visit_block(visit_data[visit_day_key], in_morning)
		visit_blocks.append(block)
		var site: Schedule.Site = get_service_site(visit_data[facility_key])


func check_valid_visit(service_code: String) -> bool:
	var valid: bool = false

	if service_code.containsn("ABA Therapy Monthly") or service_code.containsn("ESDM Therapy Monthly"):
		valid = true

	return valid


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
