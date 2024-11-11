class_name SummaryView
extends PanelContainer

var tab_id: int

@export var summary_organizer: GridContainer
@export var summary_block: PackedScene

func _ready() -> void:
	for site: Schedule.Site in Schedule.Site.values():
		var site_summary: SummarySection = summary_block.instantiate()
		summary_organizer.add_child(site_summary)
		site_summary.set_site(site)
		site_summary.client_changed.connect(_update_changed_client)
		if site == Schedule.Site.ALL_SITES:
			summary_organizer.move_child(site_summary, 0)


func _on_return_to_tab(id: int) -> void:
	if id == tab_id:
		for block: Control in summary_organizer.get_children():
			if block is SummarySection:
				block.refresh_display()


func _update_changed_client(section: SummarySection, affected_client: Client) -> void:
	for organizer: Control in summary_organizer.get_children():
		if organizer is not SummarySection or organizer == section:
			continue

		organizer.refresh_client(affected_client)
