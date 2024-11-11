class_name MainView
extends TabContainer

@export var schedule_view: ScheduleView
@export var summary_view: SummaryView
@export var therapist_adder: TherapistAdder
@export var client_adder: PanelContainer

func _ready() -> void:
	schedule_view.tab_id = get_tab_idx_from_control(schedule_view)
	summary_view.tab_id = get_tab_idx_from_control(summary_view)
	client_adder.tab_id = get_tab_idx_from_control(client_adder)
	tab_changed.connect(schedule_view._on_return_to_tab)
	tab_changed.connect(summary_view._on_return_to_tab)
	tab_changed.connect(client_adder._on_return_to_tab)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		CaseloadData.save()
		CaseloadData.release_therapist_references()
