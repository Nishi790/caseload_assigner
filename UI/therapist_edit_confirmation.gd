extends ConfirmationDialog

@onready var cancel_button = get_cancel_button()

func confirm_id(value: float) -> void:
	dialog_text = "Please confirm that you want to change the therapist's Alayacare ID to %d. \n
	Note that changing an existing therapist's Alaycare ID may have unpredictable consequences." % value
	cancel_button.show()


func save_error_missing_id() -> void:
	dialog_text = "Therapists must have an assigned Alayacare ID, please add one and try again."
	cancel_button.hide()


func save_error_missing_name() -> void:
	dialog_text = "Therapists must have a name. Please input a name and try again."
	cancel_button.hide()
