## Names of the keys bound to an input action (project.godot [input], M20.0),
## for UI text such as "L or Esc to close". Presentation only.
class_name InputNames
extends RefCounted


## The first key bound to `action` ("" when it has none).
static func key_of(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var key := ev as InputEventKey
			return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != KEY_NONE \
					else key.keycode)
	return ""
