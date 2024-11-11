class_name TherapistEntry
extends HBoxContainer

var therapist: Therapist

const block_name: StringName = &"block"

@export var name_label: Label

@export var mon_am_label: Label
@export var tues_am_label: Label
@export var wed_am_label: Label
@export var thurs_am_label: Label
@export var fri_am_label: Label

@export var mon_pm_label: Label
@export var tues_pm_label: Label
@export var wed_pm_label: Label
@export var thurs_pm_label: Label
@export var fri_pm_label: Label

var all_labels: Array[Label]


func _ready() -> void:
	all_labels = [mon_am_label, tues_am_label, wed_am_label, thurs_am_label,
	fri_am_label, mon_pm_label, tues_pm_label, wed_pm_label, thurs_pm_label, fri_pm_label]

	mon_am_label.set_meta(block_name, Schedule.Block.MONDAY_AM)
	mon_pm_label.set_meta(block_name, Schedule.Block.MONDAY_PM)
	tues_am_label.set_meta(block_name, Schedule.Block.TUESDAY_AM)
	tues_pm_label.set_meta(block_name, Schedule.Block.TUESDAY_PM)
	wed_am_label.set_meta(block_name, Schedule.Block.WEDNESDAY_AM)
	wed_pm_label.set_meta(block_name, Schedule.Block.WEDNESDAY_PM)
	thurs_am_label.set_meta(block_name, Schedule.Block.THURSDAY_AM)
	thurs_pm_label.set_meta(block_name, Schedule.Block.THURSDAY_PM)
	fri_am_label.set_meta(block_name, Schedule.Block.FRIDAY_AM)
	fri_pm_label.set_meta(block_name, Schedule.Block.FRIDAY_PM)



func set_therapist(new_therapist: Therapist, site: Schedule.Site = Schedule.Site.ALL_SITES) -> void:
	therapist = new_therapist
	_display_therapist(site)


func update_display(target_site: Schedule.Site = Schedule.Site.ALL_SITES) -> void:
	_display_therapist(target_site)


func _display_therapist(target_site: Schedule.Site) -> void:
	name_label.set_text(therapist.therapist_name)
	for block: Schedule.Block in therapist.work_schedule:
		var site: Schedule.Site = therapist.work_schedule[block]

		if target_site != Schedule.Site.ALL_SITES:
			if site != target_site:
				continue

		var target_label: Label = find_label(block)
		var panel: PanelContainer = target_label.get_parent()

		if therapist.admin_blocks.has(block):
			panel.theme_type_variation = "free"
			target_label.set_text(Schedule.get_site_string(site))

		else:
			panel.theme_type_variation = ""
			target_label.set_text("")




func find_label(block: Schedule.Block) -> Label:
	for label: Label in all_labels:
		if label.get_meta(block_name) == block:
			return label

	return null