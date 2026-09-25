extends Resource
class_name LowPolyTerrainSculpt

## Height, paint and chunk activity for one authored hex. Stored beside the hex
## scene so the text .tscn stays small.

@export var height: PackedFloat32Array = PackedFloat32Array()
@export var paint: PackedByteArray = PackedByteArray()
@export var activity: PackedByteArray = PackedByteArray()
