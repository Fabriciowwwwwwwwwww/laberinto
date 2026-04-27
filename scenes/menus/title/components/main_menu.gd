
extends HBoxContainer

signal start_pressed
signal tienda_pressed

signal options_pressed
signal credits_pressed
@onready var ui_sound: AudioStreamPlayer2D = $"ButtonBoxMargins/ButtonBox/sonido cambio"
@onready var button_box: VBoxContainer = %ButtonBox
@onready var start_button: Button = %StartButton
@onready var tienda_button: Button = %tienda
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	ui_sound.bus = "SFX"
	quit_button.visible = OS.get_name() != "Web"

	if Transitions.is_running():
		await Transitions.finished

	_on_visibility_changed()

	for b in button_box.get_children():
		if b is Button:
			b.focus_entered.connect(_on_button_focus)
			b.mouse_entered.connect(func(): _on_mouse_enter_button(b))

func _on_mouse_enter_button(button):
	button.grab_focus()

func _on_start_button_pressed() -> void:
	start_pressed.emit()


func _on_options_button_pressed() -> void:
	options_pressed.emit()


#func _on_credits_button_pressed() -> void:
	#credits_pressed.emit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_visibility_changed() -> void:
	if visible and start_button:
		start_button.grab_focus()
func _on_button_focus():
	ui_sound.play()


func _on_tienda_pressed() -> void:
	tienda_pressed.emit()
