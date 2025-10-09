extends Node

@export var default_busses := []
@export var default_pool_size := 8

var available_players: Array[AudioStreamPlayer] = []
var busy_players: Array[AudioStreamPlayer] = []
var bus: String = "Master"
var _tweens: Dictionary = {}

func _init(possible_busses: PackedStringArray = default_busses, pool_size: int = default_pool_size) -> void:
	bus = get_possible_bus(possible_busses)
	for i in pool_size:
		increase_pool()

# --- BUS HANDLING ---

func get_possible_bus(possible_busses: PackedStringArray) -> String:
	for possible_bus in possible_busses:
		var cases: PackedStringArray = [
			possible_bus,
			possible_bus.to_lower(),
			possible_bus.to_camel_case(),
			possible_bus.to_pascal_case(),
			possible_bus.to_snake_case()
		]
		for case in cases:
			if AudioServer.get_bus_index(case) > -1:
				return case
	return "Master"

# --- CORE FUNCTIONS ---

func prepare(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	cleanup_invalid_players() # 🔒 auto-clean before use

	var player := get_player_with_resource(resource)
	if player == null:
		player = get_available_player()
	if player == null or not is_instance_valid(player):
		push_warning("SoundManager.prepare() failed: no valid AudioStreamPlayer available")
		return null

	player.stream = resource
	player.bus = override_bus if override_bus != "" else bus
	player.volume_db = linear_to_db(1.0)
	player.pitch_scale = 1
	return player


func get_available_player() -> AudioStreamPlayer:
	cleanup_invalid_players()

	while available_players.size() > 0:
		var player = available_players.pop_front()
		if is_instance_valid(player):
			busy_players.append(player)
			return player

	# if we reach here, all players were invalid
	increase_pool()
	var player = available_players.pop_front()
	if player:
		busy_players.append(player)
	return player


func get_player_with_resource(resource: AudioStream) -> AudioStreamPlayer:
	cleanup_invalid_players()

	for player in busy_players + available_players:
		if not is_instance_valid(player):
			if busy_players.has(player): busy_players.erase(player)
			if available_players.has(player): available_players.erase(player)
			continue
		if player.stream == resource:
			return player
	return null


func get_busy_player_with_resource(resource: AudioStream) -> AudioStreamPlayer:
	cleanup_invalid_players()

	for player in busy_players:
		if not is_instance_valid(player):
			busy_players.erase(player)
			continue
		if player.stream and player.stream.resource_path == resource.resource_path:
			return player
	return null


func mark_player_as_available(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return

	if busy_players.has(player):
		busy_players.erase(player)

	if available_players.size() >= default_pool_size:
		call_deferred("queue_free_player", player)
	elif not available_players.has(player):
		available_players.append(player)


func queue_free_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	if available_players.has(player):
		available_players.erase(player)
	if busy_players.has(player):
		busy_players.erase(player)
	player.queue_free()


func increase_pool() -> void:
	cleanup_invalid_players()

	# Try reclaiming a non-playing busy player first
	for player in busy_players:
		if not is_instance_valid(player):
			busy_players.erase(player)
			continue
		if not player.playing:
			mark_player_as_available(player)
			return

	# Otherwise, add a new player
	var player := AudioStreamPlayer.new()
	add_child(player)
	available_players.append(player)
	player.bus = bus
	player.finished.connect(_on_player_finished.bind(player))

# --- FADES / TWEENS ---

func fade_volume(player: AudioStreamPlayer, from_volume: float, to_volume: float, duration: float) -> AudioStreamPlayer:
	if not is_instance_valid(player):
		return null

	_remove_tween(player)

	var tween: Tween = get_tree().create_tween().bind_node(self)
	player.volume_db = from_volume

	if from_volume > to_volume:
		tween.tween_property(player, "volume_db", to_volume, duration).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(player, "volume_db", to_volume, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_tweens[player] = tween
	tween.finished.connect(_on_fade_completed.bind(player, tween, from_volume, to_volume, duration))

	return player

# --- HELPERS ---

func _remove_tween(player: AudioStreamPlayer) -> void:
	if _tweens.has(player):
		var fade: Tween = _tweens[player]
		if is_instance_valid(fade):
			fade.kill()
		_tweens.erase(player)

func cleanup_invalid_players() -> void:
	for arr in [busy_players, available_players]:
		for i in range(arr.size() - 1, -1, -1):
			if not is_instance_valid(arr[i]):
				arr.remove_at(i)

# --- SIGNALS ---

func _on_player_finished(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	mark_player_as_available(player)

func _on_fade_completed(player: AudioStreamPlayer, tween: Tween, from_volume: float, to_volume: float, duration: float) -> void:
	_remove_tween(player)
	if not is_instance_valid(player):
		return
	if to_volume <= -79.0:
		player.stop()
		mark_player_as_available(player)
