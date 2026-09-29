## A face for menus (M14.7): the head cut from the front standing frame of a
## character's baked sheet (CharacterSprite, ADR 0018), so no new art exists.
## An AtlasTexture points at the sheet; a character with no sheet gets none
## (null), and the menu simply shows no face.
## Presentation only: never changes GameState (CLAUDE.md rule 1).
class_name Portrait
extends RefCounted

## The head and shoulders inside the 64 px frame. Tuned by screenshot: it keeps
## an antinium's feelers and shows a gnoll's or drake's whole head.
const HEAD := Rect2(16, 8, 32, 32)
## The size a face is drawn at in a menu (3x the crop). The menu scenes' TextureRects use it
## with nearest-neighbour filtering.
const SIZE := Vector2(96, 96)


## The sheet region (pixels) of a face: the head crop of the front standing frame.
static func rect() -> Rect2:
	var frame := CharacterSprite.region_of("walk", "s", 0)
	return Rect2(frame.position + HEAD.position, HEAD.size)


## The look (sheet id) for an NPC: its own sheet, else its race's generic one, else "".
static func look_of_npc(db: DataDb, npc: String) -> String:
	var race := String(db.canon.npcs.get(npc, {}).get("race", ""))
	return CharacterSprite.look_for(npc, race)


## The face of a look, or null when the look has no sheet.
static func texture(look: String) -> AtlasTexture:
	if not CharacterSprite.has_sheet(look):
		return null
	var t := AtlasTexture.new()
	t.atlas = load(CharacterSprite.path_for(look))
	t.region = rect()
	return t


## The face of an NPC (canon id), or null.
static func texture_of_npc(db: DataDb, npc: String) -> AtlasTexture:
	return texture(look_of_npc(db, npc))


## Fills `view` with the face of `look` and shows it, or hides it when there is none.
## Returns whether a face is showing.
static func show_in(view: TextureRect, look: String) -> bool:
	var t := texture(look)
	view.texture = t
	view.visible = t != null
	return t != null
