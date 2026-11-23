class_name TestCase
extends RefCounted

var scene_tree: SceneTree

var _failures: PackedStringArray = PackedStringArray()
var _assertions: int = 0


func reset_counters() -> void:
	_failures = PackedStringArray()
	_assertions = 0


func get_failures() -> PackedStringArray:
	return _failures


func get_assertions_count() -> int:
	return _assertions


func assert_true(condition: bool, message: String = "") -> void:
	_assertions += 1
	if not condition:
		_failures.append(
			message if not message.is_empty() else "Esperado verdadeiro, obtido falso."
		)


func assert_false(condition: bool, message: String = "") -> void:
	_assertions += 1
	if condition:
		_failures.append(
			message if not message.is_empty() else "Esperado falso, obtido verdadeiro."
		)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual != expected:
		var detail: String = "Esperado <%s>, obtido <%s>" % [str(expected), str(actual)]
		if not message.is_empty():
			detail = "%s (%s)" % [message, detail]
		_failures.append(detail)


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual == unexpected:
		var detail: String = "Não esperado <%s>" % str(unexpected)
		if not message.is_empty():
			detail = "%s (%s)" % [message, detail]
		_failures.append(detail)


func assert_not_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value == null:
		_failures.append(
			message if not message.is_empty() else "Esperado valor não nulo, obtido null."
		)


func assert_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value != null:
		_failures.append(
			message if not message.is_empty() else "Esperado null, obtido <%s>." % str(value)
		)


func assert_contains(haystack: String, needle: String, message: String = "") -> void:
	_assertions += 1
	if not haystack.contains(needle):
		var detail: String = "Texto '%s' não contém '%s'" % [haystack, needle]
		if not message.is_empty():
			detail = "%s (%s)" % [message, detail]
		_failures.append(detail)
