## Exact floats in save JSON (ADR 0008). Godot's text-to-float parse is
## not exact (about 1 in 3 floats at 17 digits comes back 1 bit off), so a
## save writes every float as text holding its 64 bits: "f64:" + 16 hex
## digits, big-endian (0.5 → "f64:3fe0000000000000"). Ints and strings stay
## as they are. decode() also accepts plain JSON numbers (v4 and older saves).
class_name SaveCodec
extends RefCounted

const PREFIX := "f64:"


## A deep copy of `v` with every float turned into its f64 text.
static func encode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			return float_to_text(v)
		TYPE_DICTIONARY:
			var d := {}
			for k: Variant in v:
				d[k] = encode(v[k])
			return d
		TYPE_ARRAY:
			return (v as Array).map(encode)
	return v


## A deep copy of `v` with every f64 text turned back into its float.
static func decode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_STRING:
			return text_to_float(v) if (v as String).begins_with(PREFIX) else v
		TYPE_DICTIONARY:
			var d := {}
			for k: Variant in v:
				d[k] = decode(v[k])
			return d
		TYPE_ARRAY:
			return (v as Array).map(decode)
	return v


static func float_to_text(x: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	b.reverse()
	return PREFIX + b.hex_encode()


static func text_to_float(text: String) -> float:
	var b := text.substr(PREFIX.length()).hex_decode()
	if b.size() != 8:
		push_error("Bad float text in save: '%s'." % text)
		return 0.0
	b.reverse()
	return b.decode_double(0)
