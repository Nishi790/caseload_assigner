class_name Client extends Resource

signal data_changed(client_affected: Client)

@export var client_name: String:
	set(new_name):
		client_name = new_name
		data_changed.emit(self)

@export var AC_id: int

@export var scheduled_site: Schedule.Site:
	set(new_site):
		scheduled_site = new_site
		data_changed.emit(self)

@export var scheduled_blocks: Array[Schedule.Block] =  []

@export var requested_site: Schedule.Site:
	set(new_site):
		requested_site = new_site
		data_changed.emit(self)
@export var requested_blocks: Array[Schedule.Block] =  []

@export var assigned_therapists: Dictionary #Block: Therapist Resource
@export var assigned_RBA: Therapist:
	set(new_rba):
		assigned_RBA = new_rba
		data_changed.emit(self)
var rba_name: String

@export var unfilled_slots: Array[Schedule.Block]


static func deserialize_client(client_data: Dictionary) -> Client:
	var new_client: Client = Client.new()
	if client_data.has("name"):
		new_client.client_name = client_data["name"]
	if client_data.has("id"):
		new_client.AC_id = client_data["id"]
	if client_data.has("scheduled_site"):
		new_client.scheduled_site = client_data["scheduled_site"]
	if client_data.has("scheduled_blocks"):
		new_client.scheduled_blocks.assign(client_data["scheduled_blocks"])
	if client_data.has("requested_site"):
		new_client.requested_site = client_data["requested_site"]
	if client_data.has("requested_blocks"):
		new_client.requested_blocks.assign(client_data["requested_blocks"])
	if client_data.has("unfilled_blocks"):
		new_client.unfilled_slots.assign(client_data["unfilled_blocks"])
	if client_data.has("assigned_RBA"):
		new_client.rba_name = client_data["assigned_RBA"]

	new_client.unfilled_slots.sort()
	new_client.requested_blocks.sort()

	return new_client


func set_rba(therapist_list: Array[Therapist]) -> void:
	for thx: Therapist in therapist_list:
		if thx.therapist_name.matchn(rba_name):
			assigned_RBA = thx
			break


func clear_rba() -> void:
	assigned_RBA = null
	rba_name = ""


func update_assigned_therapist(block: Schedule.Block, therapist: Therapist) -> void:
	if assigned_therapists.has(block):
		var current_thx = assigned_therapists[block]
		if current_thx is Therapist:
			current_thx.free_slot(block)

	assigned_therapists[block] = therapist
	therapist.schedule_client(block, self)

	if not scheduled_blocks.has(block):
		scheduled_blocks.append(block)

	if requested_blocks.has(block) and scheduled_site == requested_site:
		requested_blocks.erase(block)

	if unfilled_slots.has(block): unfilled_slots.erase(block)

	data_changed.emit(self)


func update_scheduled_blocks(new_blocks: Array[Schedule.Block], updating_requested: bool = false) -> void:
	if updating_requested:
		for block: Schedule.Block in new_blocks:
			if not requested_blocks.has(block):
				requested_blocks.append(block)

		var blocks_to_erase: Array[Schedule.Block] = []

		for block: Schedule.Block in requested_blocks:
			if not new_blocks.has(block):
				blocks_to_erase.append(block)

		for block: Schedule.Block in blocks_to_erase:
			requested_blocks.erase(block)

		requested_blocks.sort()

	else:
		for block: Schedule.Block in new_blocks:
			if scheduled_blocks.has(block):
				continue
			elif unfilled_slots.has(block):
				continue
			else:
				unfilled_slots.append(block)

		var blocks_to_erase: Array[Schedule.Block] =  []
		for block: Schedule.Block in scheduled_blocks:
			if new_blocks.has(block):
				continue
			else:
				var thx_to_update: Therapist = assigned_therapists[block]
				thx_to_update.free_slot(block)
				assigned_therapists.erase(block)
				blocks_to_erase.append(block)
		for block: Schedule.Block in blocks_to_erase:
			scheduled_blocks.erase(block)

		blocks_to_erase.clear()

		for block: Schedule.Block in unfilled_slots:
			if not new_blocks.has(block):
				blocks_to_erase.append(block)

		for block: Schedule.Block in blocks_to_erase:
			unfilled_slots.erase(block)

		unfilled_slots.sort()
	data_changed.emit(self)


func clear_block(block: Schedule.Block) -> void:
	if scheduled_blocks.has(block):
		scheduled_blocks.erase(block)
		unfilled_slots.append(block)
		unfilled_slots.sort()

	if assigned_therapists.has(block):
		assigned_therapists.erase(block)

	data_changed.emit(self)


func add_current_block(block: Schedule.Block) -> void:
	unfilled_slots.append(block)
	unfilled_slots.sort()
	data_changed.emit(self)


func add_requested_block(block: Schedule.Block) -> void:
	requested_blocks.append(block)
	requested_blocks.sort()
	data_changed.emit(self)


func schedule_requested_blocks() -> void:
	for block: Schedule.Block in assigned_therapists.keys():
		var thx: Therapist = assigned_therapists[block]
		thx.free_slot(block)

	assigned_therapists.clear()
	scheduled_blocks.clear()
	unfilled_slots.clear()

	scheduled_site = requested_site
	unfilled_slots = requested_blocks
	requested_blocks = []


func clean_assigned_therapists() -> void:
	for block: Schedule.Block in assigned_therapists:
		var thx = assigned_therapists[block]
		if not thx is Therapist:
			assigned_therapists.erase(block)
			if scheduled_blocks.has(block):
				scheduled_blocks.erase(block)
			if not unfilled_slots.has(block):
				unfilled_slots.append(block)


func serialize_data() -> Dictionary:
	var data: Dictionary = {}
	data["name"] = client_name
	data["id"] = AC_id
	data["scheduled_site"] = scheduled_site
	data["scheduled_blocks"] = scheduled_blocks
	data["requested_site"] = requested_site
	data["requested_blocks"] = requested_blocks
	data["unfilled_blocks"] = unfilled_slots
	if assigned_RBA:
		data["assigned_RBA"] = assigned_RBA.therapist_name

	return data
