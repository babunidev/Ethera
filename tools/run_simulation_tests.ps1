$ErrorActionPreference = "Stop"
$godot = "C:\Users\Babun\AppData\Local\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
$project = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $project ".godot/global_script_class_cache.cfg"))) {
	& $godot --headless --path $project --import
}
& $godot --headless --path $project -s "res://scripts/tests/run_simulation_tests.gd"
exit $LASTEXITCODE
