class_name ShakeStep
extends CutsceneStep
## Shakes the camera: a gate slamming, a boss landing. Over at once; a
## following `WaitStep` lets it play out.

## Camera trauma (0 to 1).
@export_range(0.0, 1.0) var trauma := 0.5


func play(_run: CutsceneRun) -> void:
	Events.camera_shake_requested.emit(trauma)
