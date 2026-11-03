class_name LoadingScreen
extends CanvasLayer
## Full-screen overlay with a progress bar, shown while a mine is generated.
## Runs while the game is paused (process_mode = Always in the scene).


func start(message: String = "Generating the mine...") -> void:
	%Message.text = message
	%ProgressBar.value = 0.0
	visible = true


func set_progress(ratio: float) -> void:
	%ProgressBar.value = ratio * 100.0


func finish() -> void:
	visible = false
