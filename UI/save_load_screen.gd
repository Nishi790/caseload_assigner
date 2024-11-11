class_name SaveLoadScreen
extends PanelContainer

@export var open_button: Button
@export var save_button: Button
@export var import_button: Button
@export var quit_button: Button

@export var file_selector: FileDialog
@export var error_popup: PopupPanel
@export var error_label: Label

var last_file_path: String = ""

func _ready() -> void:
	open_button.pressed.connect(select_open_file)
	save_button.pressed.connect(select_save_file)
	import_button.pressed.connect(select_import_file)
	quit_button.pressed.connect(quit)


func select_open_file() -> void:
	file_selector.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	if not last_file_path == "":
		file_selector.set_current_dir(last_file_path)
	else:
		file_selector.set_current_dir(CaseloadData.current_save_path)
	file_selector.popup_centered()
	file_selector.file_selected.connect(open_file, CONNECT_ONE_SHOT)


func open_file(path: String) -> void:
	var number_of_parts: int = path.get_slice_count("/")
	var file_name: String = path.get_slice("/", number_of_parts - 1)
	last_file_path = path.trim_suffix(file_name)
	var err: Error = CaseloadData.load_saved_data(path)

	if err != OK:
		error_label.text = "Unable to open file: %s \n Select another file" % error_string(err)
		error_popup.popup_centered()
		await get_tree().create_timer(2).timeout
		error_popup.hide()


func select_save_file() -> void:
	file_selector.file_mode = FileDialog.FILE_MODE_SAVE_FILE

	file_selector.popup_centered()
	file_selector.file_selected.connect(save_to_file, CONNECT_ONE_SHOT)

	if not last_file_path == "":
		file_selector.set_current_dir(last_file_path)
	else:
		file_selector.set_current_dir(CaseloadData.current_save_path)


func save_to_file(path: String) -> void:
	var number_of_parts: int = path.get_slice_count("/")
	var file_name: String = path.get_slice("/", number_of_parts - 1)
	last_file_path = path.trim_suffix(file_name)

	CaseloadData.current_save_path = path
	CaseloadData.save(path)


func select_import_file() -> void:
	pass


func open_import_file(path: String) -> void:
	pass


func quit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
