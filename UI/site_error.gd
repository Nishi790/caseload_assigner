class_name SiteError extends VBoxContainer

signal site_selected(site: Schedule.Site)

@export var site_selector: OptionButton
@export var name_label: Label


func _ready() -> void:
	site_selector.item_selected.connect(_select_site)

	for site: Schedule.Site in Schedule.Site.values():
		site_selector.add_item(Schedule.get_site_string(site), site + 1)


func _select_site(index: int) -> void:
	var site: Schedule.Site = site_selector.get_item_id(index) - 1
	site_selected.emit(site)
