class_name SaveManager
extends RefCounted

## Hệ thống Lưu & Tải Tiến trình (Save/Load System) cho NOCTELYRA (M3.2 FINAL)
## Hỗ trợ ghi tạm nguyên tử (Atomic write), backup và rollback khi lỗi,
## nạp trang bị trước để tính toán chính xác Max MP/Current MP,
## thẩm định (validation) chặt chẽ và cách ly dữ liệu kiểm thử an toàn 100%.

const DEFAULT_SAVE_PATH: String = "user://noctelyra_slot1.json"
const CURRENT_VERSION: String = "1.2.0"
const SUPPORTED_VERSIONS: Array[String] = ["1.0.0", "1.1.0", "1.2.0"]

static var custom_save_path: String = ""
static var should_load_on_start: bool = false

# Các cờ mô phỏng lỗi dùng riêng cho kiểm thử an toàn ghi file (Fault Injection)
static var simulate_tmp_write_error: bool = false
static var simulate_backup_error: bool = false
static var simulate_replace_error: bool = false

static func get_save_path() -> String:
	if not custom_save_path.is_empty():
		return custom_save_path
	return DEFAULT_SAVE_PATH

static func get_tmp_path() -> String:
	return get_save_path() + ".tmp"

static func get_bak_path() -> String:
	return get_save_path() + ".bak"

static func has_save() -> bool:
	var path := get_save_path()
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()

	if text.strip_edges().is_empty():
		return false

	var test_json := JSON.new()
	var err := test_json.parse(text)
	if err != OK or not (test_json.data is Dictionary):
		return false

	var dict: Dictionary = test_json.data

	# Thẩm định phiên bản save_version
	if not dict.has("save_version") or not (dict["save_version"] is String):
		return false
	var ver: String = dict["save_version"]
	if not ver in SUPPORTED_VERSIONS:
		return false

	# Thẩm định cấu trúc dữ liệu cốt lõi bắt buộc phải tồn tại
	if not dict.has("player") or not (dict["player"] is Dictionary):
		return false
	if not dict.has("quest") or not (dict["quest"] is Dictionary):
		return false

	return true

static func delete_save() -> bool:
	var path := get_save_path()
	var success := true
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err != OK: success = false
	var tmp_path := get_tmp_path()
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)
	var bak_path := get_bak_path()
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)
	return success

static func is_boss_combat_active(world: Node) -> bool:
	if world == null:
		return false
	if "boss_battle_started" in world and world.get("boss_battle_started") == true:
		return true
	var boss = world.get_node_or_null("BossLunareth")
	if boss and is_instance_valid(boss):
		if "current_state" in boss:
			var st: int = int(boss.get("current_state"))
			# 0 là DORMANT, 7 là DEFEATED
			if st != 0 and st != 7:
				return true
	return false

static func save_game(world: Node) -> bool:
	if world == null:
		return false

	# Kiểm tra bảo vệ: Không cho phép lưu khi đang giao tranh Boss
	if is_boss_combat_active(world):
		push_warning("SaveManager: Không thể lưu game trong khi trận đánh Boss đang diễn ra!")
		return false

	var player := world.get_node_or_null("Player") as Player
	var quest_mgr := world.get_node_or_null("QuestManager") as QuestManager
	var ui := world.get_node_or_null("GameUI") as GameUI

	if player == null or quest_mgr == null:
		return false

	var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
	var p_inv := player.get_node_or_null("InventoryComponent") as InventoryComponent
	var p_eq := player.get_node_or_null("EquipmentComponent") as EquipmentComponent
	var p_spellbook := player.get_node_or_null("SpellbookComponent") as SpellbookComponent

	var save_path := get_save_path()
	var tmp_path := get_tmp_path()
	var bak_path := get_bak_path()

	var save_data: Dictionary = {
		"save_version": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {
			"position_x": player.global_position.x,
			"position_y": player.global_position.y,
			"current_health": clamp(p_health.current_health, 0.0, p_health.max_health) if p_health else 100.0,
			"current_mana": clamp(p_health.current_mana, 0.0, p_health.max_mana) if p_health else 60.0
		},
		"gold": max(0, quest_mgr.gold),
		"inventory": p_inv.to_dict() if p_inv else [],
		"equipment": p_eq.to_dict() if p_eq else {},
		"spellbook": p_spellbook.to_dict() if p_spellbook else {
			"selected_spell": "moon_bolt",
			"known_spells": ["moon_bolt", "ember_bloom", "frost_shard"],
			"spell_levels": {"moon_bolt": 1, "ember_bloom": 1, "frost_shard": 1}
		},
		"quest": {
			"state": int(quest_mgr.current_quest.current_state) if quest_mgr.current_quest else 0,
			"current_amount": int(quest_mgr.current_quest.current_amount) if quest_mgr.current_quest else 0
		},
		"defeated_enemy_ids": world.get("defeated_enemy_ids") if "defeated_enemy_ids" in world else [],
		"collected_pickup_ids": world.get("collected_pickup_ids") if "collected_pickup_ids" in world else [],
		"dropped_pickups": world.get_dropped_pickups_data() if world.has_method("get_dropped_pickups_data") else [],
		"boss": {
			"activated": world.get("boss_battle_started") if "boss_battle_started" in world else false,
			"defeated": world.get("boss_defeated") if "boss_defeated" in world else false,
			"reward_claimed": world.get("boss_reward_claimed") if "boss_reward_claimed" in world else false
		}
	}

	var json_str := JSON.stringify(save_data, "\t")

	# 1. Ghi an toàn vào file tạm .tmp (Kiểm tra fault injection)
	if simulate_tmp_write_error:
		push_error("[Mô phỏng lỗi]: Thất bại khi ghi file tạm!")
		return false

	var tmp_file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if tmp_file == null:
		push_error("Không thể mở file tạm để ghi: " + tmp_path)
		return false

	tmp_file.store_string(json_str)
	tmp_file.flush()
	tmp_file.close()

	# 2. Xác minh dữ liệu trong file tạm trước khi chạm vào file cũ
	var verify_file := FileAccess.open(tmp_path, FileAccess.READ)
	if verify_file == null:
		DirAccess.remove_absolute(tmp_path)
		return false
	var verify_text := verify_file.get_as_text()
	verify_file.close()

	var verify_json := JSON.new()
	if verify_json.parse(verify_text) != OK or not (verify_json.data is Dictionary):
		push_error("Xác minh file tạm thất bại! Giữ nguyên bản lưu cũ.")
		DirAccess.remove_absolute(tmp_path)
		return false

	# 3. Tạo bản sao lưu dự phòng .bak từ file hiện tại (nếu đã có file save cũ)
	var has_old := FileAccess.file_exists(save_path)
	if has_old:
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)

		if simulate_backup_error:
			push_error("[Mô phỏng lỗi]: Thất bại ở bước tạo bản sao lưu .bak!")
			DirAccess.remove_absolute(tmp_path)
			return false

		var copy_bak_err := DirAccess.copy_absolute(save_path, bak_path)
		if copy_bak_err != OK and not FileAccess.file_exists(bak_path):
			var bak_err := DirAccess.rename_absolute(save_path, bak_path)
			if bak_err != OK and not FileAccess.file_exists(bak_path):
				push_error("Không thể tạo bản sao lưu backup!")
				DirAccess.remove_absolute(tmp_path)
				return false

	# 4. Thay thế an toàn file chính bằng file tạm (.tmp -> save_path)
	var replace_err := DirAccess.rename_absolute(tmp_path, save_path)
	if replace_err != OK or simulate_replace_error:
		var copy_err := DirAccess.copy_absolute(tmp_path, save_path)
		if copy_err != OK or simulate_replace_error:
			push_error("Lỗi khi thay thế file save! Phục hồi bản lưu cũ từ backup.")
			if FileAccess.file_exists(bak_path):
				var restore_err := DirAccess.copy_absolute(bak_path, save_path)
				if restore_err != OK and not FileAccess.file_exists(save_path):
					DirAccess.rename_absolute(bak_path, save_path)
				if FileAccess.file_exists(save_path) and FileAccess.file_exists(bak_path):
					DirAccess.remove_absolute(bak_path)
			if FileAccess.file_exists(tmp_path):
				DirAccess.remove_absolute(tmp_path)
			return false
		DirAccess.remove_absolute(tmp_path)

	# 5. Hoàn tất thành công, dọn dẹp file backup
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)

	if ui:
		ui.show_notification("Đã lưu tiến trình game thành công!")

	return true

static func load_game(world: Node) -> bool:
	if world == null or not has_save():
		return false

	var player := world.get_node_or_null("Player") as Player
	var quest_mgr := world.get_node_or_null("QuestManager") as QuestManager
	var ui := world.get_node_or_null("GameUI") as GameUI

	if player == null or quest_mgr == null:
		push_error("load_game thất bại: World thiếu Player hoặc QuestManager.")
		return false

	var save_path := get_save_path()
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()

	var test_json := JSON.new()
	var err := test_json.parse(text)
	if err != OK or not (test_json.data is Dictionary):
		push_warning("File save hỏng hoặc sai cú pháp JSON, bỏ qua để bảo vệ game.")
		return false

	var data: Dictionary = test_json.data
	var version: String = str(data.get("save_version", ""))
	if not version in SUPPORTED_VERSIONS:
		push_warning("Phiên bản save_version không được hỗ trợ: " + version)
		return false

	# Kiểm tra các khối dữ liệu cốt lõi
	if not data.has("player") or not (data["player"] is Dictionary):
		push_warning("Thiếu dữ liệu player hợp lệ trong bản lưu.")
		return false
	if not data.has("quest") or not (data["quest"] is Dictionary):
		push_warning("Thiếu dữ liệu quest hợp lệ trong bản lưu.")
		return false

	# BƯỚC 1 (QUAN TRỌNG): Khôi phục Trang bị & Túi đồ TRƯỚC để tính toán lại Max Stats (Max MP / Sát thương)
	var p_eq := player.get_node_or_null("EquipmentComponent") as EquipmentComponent
	if p_eq:
		if data.has("equipment") and (data["equipment"] is Dictionary):
			p_eq.load_from_dict(data["equipment"])
		else:
			p_eq.load_from_dict({})

	var p_inv := player.get_node_or_null("InventoryComponent") as InventoryComponent
	if p_inv:
		if data.has("inventory") and (data["inventory"] is Array):
			p_inv.load_from_dict(data["inventory"])
		else:
			p_inv._initialize_slots()

	# BƯỚC 1.5: Khôi phục Sách Phép (SpellbookComponent - M5)
	var p_spellbook := player.get_node_or_null("SpellbookComponent") as SpellbookComponent
	if p_spellbook:
		if data.has("spellbook") and (data["spellbook"] is Dictionary):
			p_spellbook.from_dict(data["spellbook"])
		else:
			# Tương thích ngược v1.0.0 và v1.1.0: mặc định mở khóa 3 phép cấp 1
			p_spellbook.from_dict({
				"selected_spell": "moon_bolt",
				"known_spells": ["moon_bolt", "ember_bloom", "frost_shard"],
				"spell_levels": {
					"moon_bolt": 1,
					"ember_bloom": 1,
					"frost_shard": 1
				}
			})

	# BƯỚC 2: Khôi phục Player (Tọa độ & HP/MP)
	# Nhờ Bước 1 đã chạy, p_health.max_mana đã được cập nhật chính xác (80 nếu đeo moon_amulet, 60 nếu không)
	var p_data: Dictionary = data["player"]
	var raw_x = p_data.get("position_x", player.global_position.x)
	var raw_y = p_data.get("position_y", player.global_position.y)

	var px: float = float(raw_x) if typeof(raw_x) in [TYPE_FLOAT, TYPE_INT] else player.global_position.x
	var py: float = float(raw_y) if typeof(raw_y) in [TYPE_FLOAT, TYPE_INT] else player.global_position.y
	if not is_finite(px): px = 180.0
	if not is_finite(py): py = 630.0

	# Giới hạn tọa độ trong thế giới an toàn (clamp mở rộng cho Đấu trường Boss M4)
	px = clamp(px, 50.0, 6200.0)
	py = clamp(py, 100.0, 700.0)
	player.global_position = Vector2(px, py)

	var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
	if p_health:
		var raw_hp = p_data.get("current_health", p_health.max_health)
		var hp_val: float = float(raw_hp) if typeof(raw_hp) in [TYPE_FLOAT, TYPE_INT] else p_health.max_health
		p_health.current_health = clamp(hp_val, 0.0, p_health.max_health)

		var raw_mp = p_data.get("current_mana", p_health.max_mana)
		var mp_val: float = float(raw_mp) if typeof(raw_mp) in [TYPE_FLOAT, TYPE_INT] else p_health.max_mana
		p_health.current_mana = clamp(mp_val, 0.0, p_health.max_mana)

		p_health.emit_signal("health_changed", p_health.current_health, p_health.max_health)
		p_health.emit_signal("mana_changed", p_health.current_mana, p_health.max_mana)

	# BƯỚC 3: Khôi phục & Validate Vàng & Nhiệm vụ
	var raw_gold = data.get("gold", 0)
	var val_gold: int = int(raw_gold) if typeof(raw_gold) in [TYPE_INT, TYPE_FLOAT] else 0
	quest_mgr.gold = clamp(val_gold, 0, 999999)
	quest_mgr.emit_signal("gold_changed", quest_mgr.gold)

	var q_data: Dictionary = data["quest"]
	var raw_state = q_data.get("state", 0)
	var q_state: int = int(raw_state) if typeof(raw_state) in [TYPE_INT, TYPE_FLOAT] else 0
	q_state = clamp(q_state, 0, 3)

	var raw_amt = q_data.get("current_amount", 0)
	var q_amt: int = int(raw_amt) if typeof(raw_amt) in [TYPE_INT, TYPE_FLOAT] else 0

	if quest_mgr.current_quest:
		quest_mgr.current_quest.current_state = q_state as QuestData.State
		quest_mgr.current_quest.current_amount = clamp(q_amt, 0, quest_mgr.current_quest.target_amount)
		if q_state == QuestData.State.COMPLETED:
			quest_mgr.current_quest.current_amount = quest_mgr.current_quest.target_amount

		if ui:
			ui.update_quest_info(quest_mgr.current_quest)
			ui.update_gold(quest_mgr.gold)

	# BƯỚC 4: Khôi phục trạng thái vật phẩm thế giới và quái vật
	var raw_collected = data.get("collected_pickup_ids", [])
	var collected_ids: Array = raw_collected if raw_collected is Array else []

	var raw_dropped = data.get("dropped_pickups", [])
	var dropped_pickups: Array = raw_dropped if raw_dropped is Array else []

	var raw_defeated = data.get("defeated_enemy_ids", [])
	var defeated_ids: Array = raw_defeated if raw_defeated is Array else []

	if world.has_method("restore_world_state"):
		world.restore_world_state(collected_ids, dropped_pickups, defeated_ids)

	# BƯỚC 5: Khôi phục trạng thái Boss Lunareth (M4)
	var raw_boss = data.get("boss", {})
	var boss_dict: Dictionary = raw_boss if raw_boss is Dictionary else {}
	var b_activated: bool = bool(boss_dict.get("activated", false))
	var b_defeated: bool = bool(boss_dict.get("defeated", false))
	var b_reward: bool = bool(boss_dict.get("reward_claimed", false))

	if world.has_method("restore_boss_state"):
		world.restore_boss_state(b_activated, b_defeated, b_reward)

	# Đồng bộ danh sách quái đã chết vào QuestManager để chống đếm trùng
	for did in defeated_ids:
		var sid := str(did)
		if not sid in quest_mgr._killed_enemy_ids:
			quest_mgr._killed_enemy_ids.append(sid)

	if ui:
		ui.show_notification("Đã tải bản lưu thành công!")

	return true
