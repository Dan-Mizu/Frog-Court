extends Node

#region Sounds
func play_and_wait_sound(sound: AudioStream, override_bus: String = "Ambience") -> void: await play_sound(sound, override_bus).finished

func play_sound(sound: AudioStream, override_bus: String = "Ambience") -> AudioStreamPlayer: return SoundManager.play_sound(sound, override_bus)

func fade_out_sound(player: AudioStreamPlayer, duration: float = 1.0) -> void: SoundManager.sound_effects.fade_volume(player, player.volume_db, -80.0, duration)
#endregion
