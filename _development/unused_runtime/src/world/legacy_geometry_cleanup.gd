extends Node2D

## The previous prototype assembled the meadow from overlapping rectangles and
## floating one-way platforms. Remove those nodes before the first physics frame.

const KEEP := {
	"NoctisTerrain": true,
	"LeftWall": true,
	"RightWall": true,
	"ArenaBarrier": true,
}


func _ready() -> void:
	for child in get_children():
		if not KEEP.has(child.name):
			child.queue_free()

