$ErrorActionPreference = "Stop"
$godot = "C:\Users\Babun\AppData\Local\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
$project = Split-Path -Parent $PSScriptRoot
# Always import: adding a new class_name otherwise fails with a confusing "could not find
# type" parse error until the global class cache is rebuilt.
& $godot --headless --path $project --import | Out-Null
& $godot --headless --path $project -s "res://scripts/tests/run_simulation_tests.gd"
exit $LASTEXITCODE
