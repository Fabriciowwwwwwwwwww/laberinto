@tool
class_name Talker
extends NPC

const DEFAULT_DIALOGUE: DialogueResource = preload("res://scenes/quests/story_quests/template/3_template_sequence_puzzle/dialogo_mayordomo_intro.dialogue")

@export var npc_name: String
@export var dialogue: DialogueResource = DEFAULT_DIALOGUE

var _previous_look_at_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED

@onready var interact_area: InteractArea = $interact_area


func _ready() -> void:
	super._ready()

	if Engine.is_editor_hint():
		return

	if not interact_area.interaction_started.is_connected(_on_interaction_started):
		interact_area.interaction_started.connect(_on_interaction_started)

	if npc_name != "":
		interact_area.action = "Hablar con %s" % npc_name


func _on_interaction_started(player: Player, from_right: bool) -> void:
	_previous_look_at_side = look_at_side

	if look_at_side != Enums.LookAtSide.UNSPECIFIED:
		look_at_side = Enums.LookAtSide.RIGHT if from_right else Enums.LookAtSide.LEFT

	MusicManager.fade_out(1.0)

	DialogueManager.dialogue_ended.connect(
		_on_dialogue_ended,
		CONNECT_ONE_SHOT
	)

	DialogueManager.show_dialogue_balloon(dialogue, "", [self, player])


func _on_dialogue_ended(_dialogue_resource: DialogueResource) -> void:
	MusicManager.fade_in(1.0)

	look_at_side = _previous_look_at_side

	interact_area.end_interaction()
