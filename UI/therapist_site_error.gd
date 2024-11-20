class_name StaffSiteError extends SiteError

@export var block_label: Label

var thx: Therapist

func set_up(therapist: Therapist, block: Schedule.Block) -> void:
	thx = therapist
	name_label.text = therapist.therapist_name
	block_label.text = Schedule.get_block_string(block)
	if thx.work_schedule.has(block):
		var scheduled_site: Schedule.Site = thx.work_schedule[block]
		if not scheduled_site == Schedule.Site.ALL_SITES:
			var id: int = scheduled_site + 1
			var index: int = site_selector.get_item_index(id)
			site_selector.select(index)
