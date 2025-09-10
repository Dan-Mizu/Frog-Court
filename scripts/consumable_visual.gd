extends Node3D

# references
@export_category("References")
@export var particles: PackedScene
@onready var particle_position: RemoteTransform3D = $ParticlePosition
var particle_emitter: GPUParticles3D

# create particle emitter
func _ready() -> void:
	# wait for scene tree to setup
	await get_tree().process_frame

	# create particle emitter
	particle_emitter = particles.instantiate() as GPUParticles3D
	get_tree().root.add_child(particle_emitter)
	particle_emitter.emitting = false

	# set particle position
	particle_position.remote_path = particle_emitter.get_path()

# when made visible
func _on_visibility_changed():
	if visible:
		# start particles
		particle_emitter.emitting = true
	else:
		# stop particles
		particle_emitter.emitting = false
