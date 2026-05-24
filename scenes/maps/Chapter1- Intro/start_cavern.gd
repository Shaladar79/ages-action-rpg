extends Node2D

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var player: Node2D = $Player

func _ready() -> void:
    if player_spawn == null:
        push_warning("PlayerSpawn was not found under StartCavern.")
        return

    if player == null:
        push_warning("Player was not found under StartCavern.")
        return

    player.global_position = player_spawn.global_position
