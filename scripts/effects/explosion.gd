extends Node3D

func configure_and_play(color: Color, sound: AudioStream):
	var particles: GPUParticles3D = $ExplosionParticles
	var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
	
	# --- Configure Particles ---
	# To safely change the color per-instance, we must duplicate the material.
	var mesh: Mesh = particles.draw_pass_1
	if mesh and mesh.surface_get_material(0):
		var material: StandardMaterial3D = mesh.surface_get_material(0).duplicate()
		material.albedo_color = color
		mesh.surface_set_material(0, material)

	# --- Configure Sound ---
	if sound:
		audio_player.stream = sound
		audio_player.play()
		
	# --- Start Explosion and Cleanup ---
	particles.emitting = true
	
	# Create a timer that will free the scene once the particles have finished
	var timer_duration = particles.lifetime + 0.5 # Add a small buffer
	var timer = get_tree().create_timer(timer_duration)
	timer.timeout.connect(queue_free)
