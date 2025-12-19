class_name Helpers
## Fonctions utilitaires

static func random_element(array: Array):
	if array.is_empty():
		return null
	return array[randi() % array.size()]

static func shuffle_array(array: Array) -> Array:
	var shuffled = array.duplicate()
	shuffled.shuffle()
	return shuffled

static func format_number(number: int) -> String:
	var str_num = str(abs(number))
	var result = ""
	var count = 0

	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = " " + result
		result = str_num[i] + result
		count += 1

	if number < 0:
		result = "-" + result

	return result

static func lerp_color(from: Color, to: Color, weight: float) -> Color:
	return from.lerp(to, weight)

static func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

static func ease_in_out_cubic(t: float) -> float:
	if t < 0.5:
		return 4.0 * t * t * t
	else:
		return 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0

static func clamp_vector2(v: Vector2, min_val: Vector2, max_val: Vector2) -> Vector2:
	return Vector2(
		clamp(v.x, min_val.x, max_val.x),
		clamp(v.y, min_val.y, max_val.y)
	)

static func get_direction_name(direction: Vector2) -> String:
	var angle = direction.angle()
	if angle < -PI * 0.75:
		return "left"
	elif angle < -PI * 0.25:
		return "up"
	elif angle < PI * 0.25:
		return "right"
	elif angle < PI * 0.75:
		return "down"
	else:
		return "left"
