class_name VharokOutpost
extends BaseZone

## Vharok — Tiền Đồn Quỷ tộc (Milestone M6)
## Vùng đất Quỷ tộc bán thú: Kiến trúc đá đen/tím/đỏ, NPC Rhaek,
## cổng ma pháp trở về Thánh Lâm Elyndra.

var npc_rhaek: NPC

func _init() -> void:
	zone_id = "vharok_outpost"
	zone_display_name = "Vharok — Tiền Đồn Quỷ tộc"

func _ready() -> void:
	init_zone_references()
	super._ready()

func init_zone_references() -> void:
	init_base_references()
	if npc_rhaek == null:
		npc_rhaek = get_node_or_null("NPC_Rhaek") as NPC
