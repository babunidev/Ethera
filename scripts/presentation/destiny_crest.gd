extends Control

# A small preview of the Destiny crest: four categories at the bottom, then
# eight, sixteen, eight and four nodes, then the Knot. Hover names the column.
# The nodes are not selectable.

const CATEGORIES: Array[String] = ["Combat", "Trickery", "Aid", "Social"]
const RING_COUNTS: Array[int] = [4, 8, 16, 8, 4, 1]

var _points: PackedVector2Array = PackedVector2Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
var _hover_labels: PackedStringArray = PackedStringArray()
var _drawn_labels: PackedStringArray = PackedStringArray()
var _label_below: PackedByteArray = PackedByteArray()
var _links: Array[Vector2i] = []
var _hover: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_hover = -1
		tooltip_text = ""
		queue_redraw()
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	var next: int = _hit((event as InputEventMouseMotion).position)
	if next == _hover:
		return
	_hover = next
	tooltip_text = _hover_labels[next] if next >= 0 and next < _hover_labels.size() else ""
	queue_redraw()


func _draw() -> void:
	_layout()
	var line := Color(0.62, 0.55, 0.44, 0.9)
	for link in _links:
		draw_line(_points[link.x], _points[link.y], line, 1.25, true)
	for index in _points.size():
		var fill := Color(0.78, 0.71, 0.58)
		if index == _points.size() - 1:
			fill = Color(0.9, 0.82, 0.62)
		if index == _hover:
			fill = Color(0.98, 0.92, 0.74)
		draw_circle(_points[index], _radii[index], fill)
		draw_arc(_points[index], _radii[index], 0.0, TAU, 20, Color(0.32, 0.27, 0.2), 1.0, true)
	var font: Font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	var ink := Color(0.93, 0.90, 0.82)
	draw_string(font, Vector2(0, 18), "Destiny Crest", HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, ink)
	for index in _points.size():
		var text: String = _drawn_labels[index]
		if text == "":
			continue
		var point: Vector2 = _points[index]
		var y: float = point.y + _radii[index] + 16.0 if _label_below[index] != 0 else point.y - _radii[index] - 6.0
		draw_string(font, Vector2(point.x - 48.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 96.0, 13, ink)


func _layout() -> void:
	_points = PackedVector2Array()
	_radii = PackedFloat32Array()
	_hover_labels = PackedStringArray()
	_drawn_labels = PackedStringArray()
	_label_below = PackedByteArray()
	_links = []
	if size.x < 8.0 or size.y < 8.0:
		return
	var pad_x := 18.0
	var pad_top := 36.0
	var pad_bottom := 22.0
	var inner_w: float = maxf(size.x - pad_x * 2.0, 1.0)
	var inner_h: float = maxf(size.y - pad_top - pad_bottom, 1.0)
	var rows: int = RING_COUNTS.size()
	var starts: PackedInt32Array = PackedInt32Array()
	for ring in rows:
		starts.append(_points.size())
		var count: int = RING_COUNTS[ring]
		var y: float = pad_top + inner_h * (1.0 - float(ring) / float(rows - 1))
		var spacing: float = inner_w / float(count)
		var radius: float = 11.0 if count == 1 else clampf(spacing * 0.22, 4.0, 9.0)
		for index in count:
			_points.append(Vector2(pad_x + spacing * (float(index) + 0.5), y))
			_radii.append(radius)
			if count == 1:
				_hover_labels.append("Knot")
				_drawn_labels.append("Knot")
				_label_below.append(0)
			else:
				var category: int = clampi(int(index * CATEGORIES.size() / count), 0, CATEGORIES.size() - 1)
				_hover_labels.append("%s quest" % CATEGORIES[category])
				_drawn_labels.append(CATEGORIES[category] if ring == 0 else "")
				_label_below.append(1 if ring == 0 else 0)
	for ring in rows - 1:
		var lower: int = RING_COUNTS[ring]
		var upper: int = RING_COUNTS[ring + 1]
		if upper > lower:
			for index in lower:
				_links.append(Vector2i(starts[ring] + index, starts[ring + 1] + index * 2))
				_links.append(Vector2i(starts[ring] + index, starts[ring + 1] + index * 2 + 1))
		elif upper == 1:
			for index in lower:
				_links.append(Vector2i(starts[ring] + index, starts[ring + 1]))
		else:
			for index in upper:
				_links.append(Vector2i(starts[ring] + index * 2, starts[ring + 1] + index))
				_links.append(Vector2i(starts[ring] + index * 2 + 1, starts[ring + 1] + index))


func _hit(at: Vector2) -> int:
	var found := -1
	var best := 99999.0
	for index in _points.size():
		var distance: float = at.distance_to(_points[index])
		if distance <= _radii[index] + 4.0 and distance < best:
			best = distance
			found = index
	return found
