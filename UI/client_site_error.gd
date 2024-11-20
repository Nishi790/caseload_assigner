class_name ClientSiteError extends SiteError

var affected_client: Client


func set_up(client: Client) -> void:
	affected_client = client
	name_label.text = affected_client.client_name
	if affected_client.scheduled_site == Schedule.Site.ALL_SITES:
		site_selector.select(0)
	else:
		var site_id: int = affected_client.scheduled_site as int
		site_id += 1
		var index: int = site_selector.get_item_index(site_id)
		site_selector.select(index)
