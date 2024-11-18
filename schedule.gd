class_name Schedule
extends Node

const config_path: String = "user://config.cfg"
const back_up_path: String = "user://back_ups"

enum Block {MONDAY_AM, MONDAY_PM, TUESDAY_AM, TUESDAY_PM,
WEDNESDAY_AM, WEDNESDAY_PM, THURSDAY_AM, THURSDAY_PM, FRIDAY_AM, FRIDAY_PM}

enum Site {COLONNADE = 0, LANCASTER = 1, KANATA = 2, PEMBROKE = 3, ALL_SITES = -1}


var KANATA_COLOUR: Color = Color.DARK_SLATE_BLUE
var COLONNADE_COLOUR: Color = Color.WEB_PURPLE
var LANCASTER_COLOUR: Color = Color.DARK_SALMON
var PEMBROKE_COLOUR: Color = Color.FOREST_GREEN


var active_clients: Dictionary #ID (int): Client
var alphabetical_clients: Array[Client]
var active_staff: Dictionary #ID (int): Therapist
var alphabetical_staff: Array[Therapist]


var load_failed: bool = false
var auto_save_name: String = "schedule_data.schedule"

#Settings data to save
var current_save_path: String = ""
var current_tab_index: int


static func get_site_string(site: Site) -> String:
	match site:
		Site.COLONNADE:
			return "Colonnade"
		Site.LANCASTER:
			return "Lancaster"
		Site.KANATA:
			return "Kanata"
		Site.PEMBROKE:
			return "Pembroke"
		Site.ALL_SITES:
			return "All"
	return ""


static func get_block_string(block: Block) -> String:
	match block:
		Block.MONDAY_AM:
			return "Monday am"
		Block.MONDAY_PM:
			return "Monday pm"
		Block.TUESDAY_AM:
			return "Tuesday am"
		Block.TUESDAY_PM:
			return "Tuesday pm"
		Block.WEDNESDAY_AM:
			return "Wednesday am"
		Block.WEDNESDAY_PM:
			return "Wednesday pm"
		Block.THURSDAY_AM:
			return "Thursday am"
		Block.THURSDAY_PM:
			return "Thursday pm"
		Block.FRIDAY_AM:
			return "Friday am"
		Block.FRIDAY_PM:
			return "Friday pm"

	return ""


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(back_up_path):
		DirAccess.make_dir_absolute(back_up_path)
	load_config()


	var err: Error = load_saved_data()
	if not err == OK:
		set_up_test_database()
		print("Unable to load saved_data, error: %s. Loading test database" % error_string(err))


func alphabetize_lists() -> void:
	alphabetical_clients.assign(active_clients.values())
	alphabetical_clients.sort_custom(func alphabetize(a: Client, b: Client) -> bool:
		return b.client_name > a.client_name)

	alphabetical_staff.assign(active_staff.values())
	alphabetical_staff.sort_custom(func alphabetize(a: Therapist, b: Therapist) -> bool:
		return b.therapist_name > a.therapist_name)


func save(path: String = "") -> void:
	if path == "":
		if current_save_path != "":
			path = current_save_path
		else:
			path = "user://" + auto_save_name

	if load_failed:
		var old_path: String = path.trim_suffix(".schedule")
		old_path = old_path + "_OLD.schedule"
		DirAccess.rename_absolute(path, old_path)

	var file_access: FileAccess = FileAccess.open(path, FileAccess.WRITE_READ)
	var save_dict: Dictionary = {}

	var client_dict: Dictionary = {}
	for client: Client in active_clients.values():
		var serialized_client: Dictionary = client.serialize_data()
		client_dict[client.AC_id] = serialized_client
	save_dict["Clients"] = client_dict

	var staff_dict: Dictionary = {}
	for staff: Therapist in active_staff.values():
		var serialized_staff: Dictionary = staff.serialize_data()
		staff_dict[staff.therapist_name] = serialized_staff
	save_dict["Staff"] = staff_dict

	var save_string: String = JSON.stringify(save_dict)
	file_access.store_string(save_string)
	file_access.close()


func save_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("Settings", "current_save_file", current_save_path)
	config.set_value("State", "current_tab", current_tab_index)
	config.save(config_path)


func back_up() -> void:
	var dir_access: DirAccess = DirAccess.open(back_up_path)
	var back_up_list: Array[String] = []
	back_up_list.assign(Array(dir_access.get_files()))
	back_up_list.reverse()
	while back_up_list.size() > 15:
		var back_up: String = back_up_list.pop_back()
		var delete_path: String = back_up_path.path_join(back_up)
		delete_path = ProjectSettings.globalize_path(delete_path)
		OS.move_to_trash(delete_path)
	var file_name: String = "back_up_" + Time.get_datetime_string_from_system() + ".schedule"
	file_name = file_name.replace(":", "_")
	file_name = file_name.replace("T", "_")
	var path: String = back_up_path.path_join(file_name)
	save(path)


func release_therapist_references() -> void:
	for client: Client in active_clients.values():
		client.assigned_RBA = null
		client.assigned_therapists.clear()


func load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(config_path)

	current_save_path = config.get_value("Settings", "current_save_file", "")
	current_tab_index = config.get_value("State", "current_tab", 0)


func load_saved_data(path: String = "") -> Error:
	if path == "":
		if current_save_path != "":
			path = current_save_path
		else:
			path = "user://" + auto_save_name

	if FileAccess.file_exists(path):
		var file_access: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file_access == null:
			printerr("Failed to open saved data with open error %s" % error_string(FileAccess.get_open_error()))
			load_failed = true
			return ERR_CANT_OPEN

		var file_string: String = file_access.get_as_text()
		var json_parser: JSON = JSON.new()
		var error: Error = json_parser.parse(file_string)
		if error == Error.OK:

			release_therapist_references()
			active_clients.clear()
			active_staff.clear()

			var client_dict: Dictionary = json_parser.data["Clients"]
			var thx_dict: Dictionary = json_parser.data["Staff"]
			for entry: String in client_dict:
				var new_client: Client = Client.deserialize_client(client_dict[entry])
				active_clients[new_client.AC_id] = new_client
			for entry: String in thx_dict:
				var thx: Therapist = Therapist.deserialize_thx(thx_dict[entry])
				thx.connect_clients_by_id()
				active_staff[thx.AC_id] = thx
		else:
			return error
		return OK
	return ERR_DOES_NOT_EXIST


func set_up_test_database() -> void:
	var test_staff: Therapist = Therapist.new()
	test_staff.therapist_name = "Test Rebecca"
	test_staff.AC_id = 0
	test_staff.add_work_block_to_schedule(Schedule.Block.MONDAY_AM, Schedule.Site.COLONNADE)
	test_staff.add_work_block_to_schedule(Schedule.Block.MONDAY_PM, Schedule.Site.COLONNADE)
	test_staff.add_work_block_to_schedule(Schedule.Block.TUESDAY_AM, Schedule.Site.KANATA)
	test_staff.add_work_block_to_schedule(Schedule.Block.TUESDAY_PM, Schedule.Site.KANATA)

	active_staff[test_staff.AC_id] = test_staff

	test_staff = Therapist.new()
	test_staff.therapist_name = "Test Amanda"
	test_staff.AC_id = 1
	test_staff.add_work_block_to_schedule(Schedule.Block.TUESDAY_AM, Schedule.Site.COLONNADE)
	test_staff.add_work_block_to_schedule(Schedule.Block.WEDNESDAY_AM, Schedule.Site.COLONNADE)
	test_staff.add_work_block_to_schedule(Schedule.Block.WEDNESDAY_PM, Schedule.Site.COLONNADE)
	active_staff[test_staff.AC_id] = test_staff

	var test_client: Client = Client.new()
	test_client.client_name = "Client A"
	test_client.AC_id = 5613
	test_client.update_assigned_therapist(Schedule.Block.TUESDAY_AM, test_staff)
	test_client.unfilled_slots.append(Schedule.Block.MONDAY_AM)
	test_client.unfilled_slots.append(Schedule.Block.FRIDAY_AM)
	test_client.scheduled_site = Schedule.Site.COLONNADE

	active_clients[test_client.AC_id] = test_client


func get_site_colour(site: Site) -> Color:
	match site:
		Site.COLONNADE:
			return COLONNADE_COLOUR
		Site.LANCASTER:
			return LANCASTER_COLOUR
		Site.KANATA:
			return KANATA_COLOUR
		Site.PEMBROKE:
			return PEMBROKE_COLOUR

	return Color.BLACK


func add_therapist(new_thx: Therapist) -> void:
	if active_staff.has(new_thx.AC_id):
		return
	else:
		active_staff[new_thx.AC_id] = new_thx


func delete_therapist(thx: Therapist) -> void:
	if active_staff.has(thx.AC_id):
		active_staff.erase(thx.AC_id)

	if alphabetical_staff.has(thx):
		alphabetical_staff.erase(thx)

	var check_rba: bool = false
	if thx.therapist_type == Therapist.Type.RBA:
		check_rba = true

	for block: Schedule.Block in thx.scheduled_blocks:
		var target_client: Client = thx.scheduled_blocks[block]
		target_client.clear_block(block)
	if check_rba:
		for client: Client in thx.caseload:
			if client.assigned_RBA == thx:
				client.clear_rba()


func delete_client(client: Client) -> void:
	active_clients.erase(client.AC_id)

	for block: Block in client.assigned_therapists.keys():
		var assigned_thx: Therapist = client.assigned_therapists[block]
		assigned_thx.free_slot(block)


func clean_client_entries() -> void:
	for client: Client in active_clients.values():
		client.clean_assigned_therapists()
