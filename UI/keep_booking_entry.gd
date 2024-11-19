class_name KeepBookingEntry
extends HBoxContainer

signal client_kept(client: Client)

@export var name_label: Label
@export var keep_button: Button

var entry_client: Client


func _ready() -> void:
	keep_button.pressed.connect(keep_client)


func set_up(client: Client) -> void:
	entry_client = client
	name_label.text = entry_client.client_name


func keep_client() -> void:
	client_kept.emit(entry_client)
