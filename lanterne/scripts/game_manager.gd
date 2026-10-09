# game_manager.gd
extends Node

var respawn_position: Vector2 = Vector2.ZERO
var respawn_scene: String = ""
var has_respawn_point: bool = false
var vitJ : Vector2 = Vector2.ZERO
var Changinglvl = false
var changepos : Vector2

# Conservation de l'état de la lanterne
var lantern_usure_saved: float = 100.0
var is_lanterne_saved: bool = true

# Liste des identifiants uniques des feux de camp allumés
var active_checkpoints: Array[String] = []

# --- Gestion du Combo d'Allumage Musical ---
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_TIMEOUT: float = 4.0
const NOTE_DEPART: float = 0.4

# Table des fréquences transposée de manière proportionnelle pour rester juste
const PITCH_SCALE_STEPS: Array[float] = [
	NOTE_DEPART,              # Note 1 (ex: 0.5)
	NOTE_DEPART * 1.125,      # Note 2
	NOTE_DEPART * 1.25,       # Note 3
	NOTE_DEPART * 1.333,      # Note 4
	NOTE_DEPART * 1.5,        # Note 5
	NOTE_DEPART * 1.667,      # Note 6
	NOTE_DEPART * 1.875,      # Note 7
	NOTE_DEPART * 2.0         # Note 8 (Octave supérieure du départ)
]


func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0 # Réinitialise le combo si le délai de 4s est dépassé


func register_ignition_combo() -> float:
	# Si le timer est actif (allumage dans les 4s), on incrémente le combo
	if combo_timer > 0.0:
		combo_count += 1
	else:
		combo_count = 0 # Premier allumage : combo remis à zéro
	
	# Réinitialise le chrono de 4 secondes
	combo_timer = COMBO_TIMEOUT
	
	# Récupère le pitch correspondant au combo actuel
	var index = min(combo_count, PITCH_SCALE_STEPS.size() - 1)
	return PITCH_SCALE_STEPS[index]


# Réinitialise le combo d'allumage (à appeler lors de la mort du joueur)
func reset_combo() -> void:
	combo_count = 0
	combo_timer = 0.0


func set_respawn_point(pos: Vector2, scene_path: String) -> void:
	reset_combo()
	respawn_position = pos
	respawn_scene = scene_path
	has_respawn_point = true


func register_checkpoint(checkpoint_id: String) -> void:
	if not active_checkpoints.has(checkpoint_id):
		active_checkpoints.append(checkpoint_id)


func is_checkpoint_active(checkpoint_id: String) -> bool:
	return active_checkpoints.has(checkpoint_id)
