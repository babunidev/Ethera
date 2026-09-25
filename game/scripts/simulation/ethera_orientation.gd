extends RefCounted
class_name EtheraOrientation

# One cue per event. The index is the presentation sequence, not world state.
# The mix is deterministic so a test can say which sign a given event produces.

const CUE_WIND_WAVE := "ground_wind_wave"
const CUE_GLINT := "ground_glint"


static func cue_kind(index: int) -> String:
	var mixed: int = (index * 1103515245 + 12345) & 0x7fffffff
	if mixed % 2 == 0:
		return CUE_WIND_WAVE
	return CUE_GLINT
