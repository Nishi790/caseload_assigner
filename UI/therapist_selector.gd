class_name TherapistSelector
extends PopupPanel

signal therapist_selected(thx: Therapist)

@export var therapist_list: ItemList
@export var confirm_button: Button
@export var delete_button: Button
@export var cancel_button: Button


func _ready() -> void:
	cancel_button.pressed.connect(hide)
	delete_button.pressed.connect(delete_therapist)
	confirm_button.pressed.connect(select_therapist)

	therapist_list.item_selected.connect(show_confirm_delete)
	_update_item_list()



func delete_therapist() -> void:
	var selected_therapists: Array = therapist_list.get_selected_items()
	if selected_therapists.is_empty():
		return
	var therapist_index = selected_therapists[0]
	var chosen_thx: Therapist = therapist_list.get_item_metadata(therapist_index)

	CaseloadData.delete_therapist(chosen_thx)
	_update_item_list()


func select_therapist() -> void:
	var selected_therapists: Array = therapist_list.get_selected_items()
	if selected_therapists.is_empty():
		return
	var therapist_index = selected_therapists[0]
	var chosen_thx: Therapist = therapist_list.get_item_metadata(therapist_index)

	therapist_selected.emit(chosen_thx)
	hide()


func show_confirm_delete(_index: int) -> void:
	confirm_button.show()
	delete_button.show()


func _update_item_list() -> void:
	therapist_list.clear()
	var index: int = 0
	for thx: Therapist in CaseloadData.active_staff:
		therapist_list.add_item(thx.therapist_name)
		therapist_list.set_item_metadata(index, thx)
		index += 1

	therapist_list.deselect_all()
	confirm_button.hide()
	delete_button.hide()
