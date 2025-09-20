extends Resource
class_name PhaseResponse

enum Phase {
	NONE,
	CLAIM
}

@export var phase: Phase
@export var user_id: String
@export var user_display_name: String
