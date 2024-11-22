class_name TherapistAdder
extends PanelContainer

signal therapist_created(therapist: Therapist)

const meta_key: StringName = &"block"

@export var confirm_box: ConfirmationDialog

@export var therapist_selector: TherapistSelector

@export var create_new_button: Button
@export var edit_existing: Button

@export var name_line: LineEdit
@export var ac_id_selector: SpinBox
@export var role_selector: OptionButton

@export var monday_location: OptionButton
@export var monday_am_checkbox: CheckBox
@export var monday_pm_checkbox: CheckBox

@export var tuesday_location: OptionButton
@export var tuesday_am_checkbox: CheckBox
@export var tuesday_pm_checkbox: CheckBox

@export var wednesday_location: OptionButton
@export var wednesday_am_checkbox: CheckBox
@export var wednesday_pm_checkbox: CheckBox

@export var thursday_location: OptionButton
@export var thursday_am_checkbox: CheckBox
@export var thursday_pm_checkbox: CheckBox

@export var friday_location: OptionButton
@export var friday_am_checkbox: CheckBox
@export var friday_pm_checkbox: CheckBox

@export var confirm: Button

var all_days: Array[CheckBox]
var all_site_selectors: Array[OptionButton]

var therapist: Therapist
var last_AC_id: int = 0

func _ready() -> void:
	ac_id_selector.value_changed.connect(confirm_id_change)

	monday_am_checkbox.set_meta(meta_key, Schedule.Block.MONDAY_AM)
	monday_pm_checkbox.set_meta(meta_key, Schedule.Block.MONDAY_PM)
	tuesday_am_checkbox.set_meta(meta_key, Schedule.Block.TUESDAY_AM)
	tuesday_pm_checkbox.set_meta(meta_key, Schedule.Block.TUESDAY_PM)
	wednesday_am_checkbox.set_meta(meta_key, Schedule.Block.WEDNESDAY_AM)
	wednesday_pm_checkbox.set_meta(meta_key, Schedule.Block.WEDNESDAY_PM)
	thursday_am_checkbox.set_meta(meta_key, Schedule.Block.THURSDAY_AM)
	thursday_pm_checkbox.set_meta(meta_key, Schedule.Block.THURSDAY_PM)
	friday_am_checkbox.set_meta(meta_key, Schedule.Block.FRIDAY_AM)
	friday_pm_checkbox.set_meta(meta_key, Schedule.Block.FRIDAY_PM)

	monday_location.item_selected.connect(_set_site.bind(monday_location))
	tuesday_location.item_selected.connect(_set_site.bind(tuesday_location))
	wednesday_location.item_selected.connect(_set_site.bind(wednesday_location))
	thursday_location.item_selected.connect(_set_site.bind(thursday_location))
	friday_location.item_selected.connect(_set_site.bind(friday_location))

	confirm.pressed.connect(save_therapist)

	all_days = [monday_am_checkbox, monday_pm_checkbox, tuesday_am_checkbox, tuesday_pm_checkbox, wednesday_am_checkbox, wednesday_pm_checkbox,
	thursday_am_checkbox, thursday_pm_checkbox, friday_am_checkbox, friday_pm_checkbox]

	for day: CheckBox in all_days:
		day.toggled.connect(_set_block_available.bind(day.get_meta(meta_key)))

	all_site_selectors = [monday_location, tuesday_location, wednesday_location, thursday_location, friday_location]

	for site_selector: OptionButton in all_site_selectors:
		site_selector.set_item_metadata(1, Schedule.Site.COLONNADE)
		site_selector.set_item_metadata(2, Schedule.Site.LANCASTER)
		site_selector.set_item_metadata(3, Schedule.Site.KANATA)
		site_selector.set_item_metadata(4, Schedule.Site.PEMBROKE)

	therapist = Therapist.new()
	therapist_created.connect(CaseloadData.add_therapist)
	therapist_selector.therapist_selected.connect(_edit_therapist)

	edit_existing.pressed.connect(_open_existing_therapist)
	create_new_button.pressed.connect(_create_therapist)


func _create_therapist() -> void:
	reset_creator()


func _open_existing_therapist() -> void:
	therapist_selector.popup_centered()


func _edit_therapist(thx: Therapist) -> void:
	therapist = thx
	name_line.text = therapist.therapist_name
	create_new_button.disabled = true
	edit_existing.disabled = true

	var role: Therapist.Type = therapist.therapist_type
	role_selector.select(role)

	var id: int = therapist.AC_id
	ac_id_selector.set_value_no_signal(id)
	last_AC_id = id

	for box: CheckBox in all_days:
		if therapist.work_schedule.keys().has(box.get_meta(meta_key)):
			box.set_pressed_no_signal(true)

	show_day_location(Schedule.Block.MONDAY_AM, Schedule.Block.MONDAY_PM, monday_location)
	show_day_location(Schedule.Block.TUESDAY_AM, Schedule.Block.TUESDAY_PM, tuesday_location)
	show_day_location(Schedule.Block.WEDNESDAY_AM, Schedule.Block.WEDNESDAY_PM, wednesday_location)
	show_day_location(Schedule.Block.THURSDAY_AM, Schedule.Block.THURSDAY_PM, thursday_location)
	show_day_location(Schedule.Block.FRIDAY_AM, Schedule.Block.FRIDAY_PM, friday_location)


func show_day_location(block: Schedule.Block, alt_block: Schedule.Block, selector: OptionButton) -> void:
	if therapist.work_schedule.has(block):
		selector.select(therapist.work_schedule[block]+1)
	elif therapist.work_schedule.has(alt_block):
		selector.select(therapist.work_schedule[alt_block]+1)



func _set_block_available(toggle_state: bool, block: Schedule.Block) -> void:
	if toggle_state:
		var site: Schedule.Site = _get_site(block)
		therapist.add_work_block_to_schedule(block, site)
		print("Block added: %s" % Schedule.get_block_string(block))

	if not toggle_state:
		therapist.remove_block_from_schedule(block)


func _get_site(block: Schedule.Block) -> Schedule.Site:
	var site

	match block:
		Schedule.Block.MONDAY_AM, Schedule.Block.MONDAY_PM:
			site = monday_location.get_selected_metadata()

		Schedule.Block.TUESDAY_AM, Schedule.Block.TUESDAY_PM:
			site = tuesday_location.get_selected_metadata()

		Schedule.Block.WEDNESDAY_AM, Schedule.Block.WEDNESDAY_PM:
			site = wednesday_location.get_selected_metadata()

		Schedule.Block.THURSDAY_AM, Schedule.Block.THURSDAY_PM:
			site = thursday_location.get_selected_metadata()

		Schedule.Block.FRIDAY_AM, Schedule.Block.FRIDAY_PM:
			site = friday_location.get_selected_metadata()

		_:
			site = Schedule.Site.COLONNADE

	if site == null:
		site = -1

	return site


func _set_site(_site_index: int, day_selector: OptionButton) -> void:
	var target_blocks: Array[Schedule.Block] = []

	match day_selector:
		monday_location:
			target_blocks.assign([Schedule.Block.MONDAY_AM, Schedule.Block.MONDAY_PM])
		tuesday_location:
			target_blocks.assign([Schedule.Block.TUESDAY_AM, Schedule.Block.TUESDAY_PM])
		wednesday_location:
			target_blocks.assign([Schedule.Block.WEDNESDAY_AM, Schedule.Block.WEDNESDAY_PM])
		thursday_location:
			target_blocks.assign([Schedule.Block.THURSDAY_AM, Schedule.Block.THURSDAY_PM])
		friday_location:
			target_blocks.assign([Schedule.Block.FRIDAY_AM, Schedule.Block.FRIDAY_PM])

	for block in target_blocks:
		if therapist.work_schedule.has(block):
			therapist.add_work_block_to_schedule(block, day_selector.get_selected_metadata())


func confirm_id_change(value: float) -> void:
	confirm_box.popup_centered()
	confirm_box.confirm_id(value)
	confirm_box.confirmed.connect(_set_AC_id.bind(value), ConnectFlags.CONNECT_ONE_SHOT)
	confirm_box.canceled.connect(_reset_id_selector, ConnectFlags.CONNECT_ONE_SHOT)


func _reset_id_selector() -> void:
	ac_id_selector.set_value_no_signal(last_AC_id)


func _set_AC_id(value: float) -> void:
	if confirm_box.canceled.is_connected(_reset_id_selector):
		confirm_box.canceled.disconnect(_reset_id_selector)
	therapist.AC_id = int(value)
	last_AC_id = int(value)


func reset_creator() -> void:
	create_new_button.disabled = false
	edit_existing.disabled = false
	therapist = null
	for day_box: CheckBox in all_days:
		day_box.set_pressed_no_signal(false)
	for site_selector: OptionButton in all_site_selectors:
		site_selector.select(0)

	name_line.clear()
	ac_id_selector.set_value_no_signal(0)
	therapist = Therapist.new()


func save_therapist() -> void:
	if therapist.AC_id == 0:
		confirm_box.popup_centered()
		confirm_box.save_error_missing_id()
		await confirm_box.confirmed
		return

	therapist.therapist_name = name_line.text.strip_edges()
	if therapist.therapist_name.is_empty():
		confirm_box.popup_centered()
		confirm_box.save_error_missing_name()
		await confirm_box.confirmed
		return

	therapist.therapist_type = role_selector.get_selected_id() as Therapist.Type
	therapist_created.emit(therapist)

	print("%s is available: " % therapist.therapist_name)
	print(therapist.work_schedule)

	reset_creator()
