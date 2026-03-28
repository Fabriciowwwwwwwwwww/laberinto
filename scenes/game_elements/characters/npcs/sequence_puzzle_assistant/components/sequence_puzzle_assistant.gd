

@tool
class_name SequencePuzzleAssistant
extends Talker

## The puzzle that this NPC can help the player with. The [member Talker.dialogue] configured on
## this node can refer to this property as [code]puzzle[/code].


## The [member Talker.dialogue] configured on this node can check and modify this property to play
## different dialogue for the player's first interaction with this NPC, if desired.
var first_conversation: bool = true

## Señal para indicar que el jugador terminó de hablar con el NPC.
signal interaction_ended

## Lógica del puzzle

## Sobreescribimos para emitir la señal cuando el diálogo termine
func _on_dialogue_ended(_dialogue_resource: DialogueResource) -> void:
	super._on_dialogue_ended(_dialogue_resource)
	print("🟡 [NPC] Señal de fin de interacción recibida. Emite 'interaction_ended'")
	interaction_ended.emit()
