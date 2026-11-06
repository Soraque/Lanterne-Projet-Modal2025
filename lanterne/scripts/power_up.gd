extends Node2D

@onready var fenetre_lancer: Panel = $"../../../../../UpperLayer/Fenetre_lancer"
@onready var button_quit: Button = $"../../../../../UpperLayer/Fenetre_lancer/Disposition/VBoxContainer/HBoxContainer/Button_quit"
@onready var player: CharacterBody2D = $"../../../../../PlayerLayer/player"

var _focus_precedent: Control
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_zone_body_entered(body: Node2D) -> void:
	if is_visible_in_tree():
		_focus_precedent = get_viewport().gui_get_focus_owner()
		button_quit.grab_focus.call_deferred()
		button_quit._focus_precedent = _focus_precedent
	player.dblq_lancer=true
	fenetre_lancer.afficher()
