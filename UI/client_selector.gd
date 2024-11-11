class_name ClientSelector
extends PopupPanel

signal client_selected(client: Client)

@export var client_list: ItemList
@export var confirm_button: Button
@export var delete_button: Button
@export var cancel_button: Button

func _ready() -> void:
	confirm_button.pressed.connect(_edit_client)
	delete_button.pressed.connect(_delete_client)
	cancel_button.pressed.connect(hide)
	about_to_popup.connect(_update_client_list)
	_update_client_list()



func _edit_client() -> void:
	var client: Client = _find_selected_client()
	if client != null:
		client_selected.emit(client)
		hide()


func _delete_client() -> void:
	var client: Client = _find_selected_client()
	if not client == null:
		CaseloadData.delete_client(client)
	client_list.deselect_all()


func _update_client_list() -> void:
	client_list.clear()

	var index: int = 0
	for client: Client in CaseloadData.active_clients.values():
		var id_string: String = str(client.AC_id) + " " + client.client_name
		client_list.add_item(id_string)
		client_list.set_item_metadata(index, client)
		index += 1


func _find_selected_client() -> Client:
	var selections: Array = client_list.get_selected_items()
	if selections.is_empty():
		return null
	else:
		var client: Client = client_list.get_item_metadata(selections[0]) as Client
		return client
