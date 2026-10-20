class_name ElyndraGlade
extends BaseZone

## Elyndra — Thánh Lâm Tinh Linh (Milestone M6)
## Vùng đất Tinh Linh: Nền rừng ma pháp xanh ngọc/bạc/tím nhạt, NPC Kaelis,
## Cổ Tinh Thạch, cổng trở về Rừng Noctis và cổng dẫn tới Tiền Đồn Vharok.

var npc_kaelis: NPC
var ancient_crystal: AncientCrystal

func _init() -> void:
	zone_id = "elyndra_glade"
	zone_display_name = "Elyndra — Thánh Lâm Tinh Linh"

func _ready() -> void:
	init_zone_references()
	super._ready()

func init_zone_references() -> void:
	init_base_references()
	if npc_kaelis == null:
		npc_kaelis = get_node_or_null("NPC_Kaelis") as NPC
	if ancient_crystal == null:
		ancient_crystal = get_node_or_null("AncientCrystal") as AncientCrystal
