extends SceneTree

func _initialize() -> void:
	var tests := EtheraSimulationTests.new()
	var failed: int = tests.run()
	quit(1 if failed > 0 else 0)
