# game_manager.gd
extends Node

var respawn_position: Vector2 = Vector2.ZERO
var respawn_scene: String = ""
var has_respawn_point: bool = false
var vitJ : Vector2 = Vector2.ZERO
var Changinglvl = false
var changepos : Vector2
var soleilallume: bool = false

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
	NOTE_DEPART,                # Note 1 (ex: 0.5)
	NOTE_DEPART * 1.125,      # Note 2
	NOTE_DEPART * 1.25,        # Note 3
	NOTE_DEPART * 1.333,      # Note 4
	NOTE_DEPART * 1.5,         # Note 5
	NOTE_DEPART * 1.667,      # Note 6
	NOTE_DEPART * 1.875,      # Note 7
	NOTE_DEPART * 2.0          # Note 8 (Octave supérieure du départ)
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


func fin() -> void:
	# 1. Attends beaucoup plus avant le début du fondu (ex: 5 secondes, ajustable)
	await Engine.get_main_loop().create_timer(5.0).timeout
	
	var current_scene = Engine.get_main_loop().current_scene
	if not current_scene:
		return
		
	# Création d'un CanvasLayer pour l'UI de fin par-dessus tout
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	current_scene.add_child(canvas_layer)
	
	# Création du fond blanc (ColorRect)
	var color_rect = ColorRect.new()
	color_rect.color = Color(1, 1, 1, 0) # Blanc transparent au départ
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(color_rect)
	
	# 2. Fondu vers le blanc sur 2 secondes
	var tween_blanc = canvas_layer.create_tween()
	tween_blanc.tween_property(color_rect, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	await tween_blanc.finished
	
	# 3. Attend 1 seconde une fois l'écran complètement blanc
	await Engine.get_main_loop().create_timer(1.0).timeout
	
	# Création du grand Label "FIN" en noir (apparaît directement)
	var label = Label.new()
	label.text = "FIN"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.modulate = Color(0, 0, 0, 1) # Noir opaque dès son apparition
	label.add_theme_font_size_override("font_size", 120)
	var custom_font = load("res://assets/Moria_DF.TTF")
	label.add_theme_font_override("font", custom_font)
	canvas_layer.add_child(label)
	
	# 4. Attend 5 secondes après l'apparition du "FIN"
	await Engine.get_main_loop().create_timer(5.0).timeout
	
	# 5. Fait apparaître un fondu au noir par-dessus pour la transition vers le menu
	var color_rect_noir = ColorRect.new()
	color_rect_noir.color = Color(0, 0, 0, 0) # Noir transparent
	color_rect_noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(color_rect_noir)
	
	var tween_noir = canvas_layer.create_tween().set_parallel(true)
	tween_noir.tween_property(color_rect_noir, "color:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	tween_noir.tween_property(label, "modulate:a", 0.0, 1.5) # Disparition douce du texte
	await tween_noir.finished
	
	# 6. Change la scène vers le menu (ui.tscn)
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui.tscn") # Adaptez le chemin selon l'emplacement exact de votre scène ui.tscn
	soleilallume = false

func register_checkpoint(checkpoint_id: String) -> void:
	if not active_checkpoints.has(checkpoint_id):
		active_checkpoints.append(checkpoint_id)


func is_checkpoint_active(checkpoint_id: String) -> bool:
	return active_checkpoints.has(checkpoint_id)
