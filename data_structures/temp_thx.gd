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


func add_admin(block: Schedule.Block, site: Schedule.Site) -> void:
	scheduled_admin[block] = site
