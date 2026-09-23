## Helpers for dotted tags ("cooking.stew"). A weight on a tag also
## applies to its children: "cooking" matches "cooking.stew".
class_name Tags
extends RefCounted

const NAME_PATTERN := "^[a-z0-9_]+(\\.[a-z0-9_]+)*$"


## "cooking.stew" → "cooking"; a top-level tag → "".
static func parent_of(tag: String) -> String:
	var i := tag.rfind(".")
	return "" if i == -1 else tag.substr(0, i)


## True if `tag` is `key` or a child of `key`.
static func matches(key: String, tag: String) -> bool:
	return tag == key or tag.begins_with(key + ".")


## Weight for `tag` from a {tag: weight} map. The most specific key wins.
static func match_weight(weights: Dictionary, tag: String) -> float:
	var t := tag
	while t != "":
		if weights.has(t):
			return float(weights[t])
		t = parent_of(t)
	return 0.0


## Scales weights so they sum to 1.0. Keeps key order.
static func normalize(weights: Dictionary) -> Dictionary:
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	var out := {}
	if total <= 0.0:
		return out
	for k: String in weights:
		out[k] = float(weights[k]) / total
	return out


## Share of the tag weight that matches any of the `focus` tags (0–1 for normalised tags).
static func overlap(tags: Dictionary, focus: Array) -> float:
	var sum := 0.0
	for tag: String in tags:
		for f: String in focus:
			if matches(f, tag):
				sum += float(tags[tag])
				break
	return sum


## Checks tag names and that every dotted tag has its parent in the registry.
static func validate_registry(registry: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var re := RegEx.create_from_string(NAME_PATTERN)
	for tag: String in registry:
		if re.search(tag) == null:
			errors.append("Tag '%s' is not a valid name." % tag)
			continue
		var parent := parent_of(tag)
		if parent != "" and not registry.has(parent):
			errors.append("Tag '%s' has no parent '%s' in the registry." % [tag, parent])
	return errors
