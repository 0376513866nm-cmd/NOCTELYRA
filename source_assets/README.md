# Source Assets Documentation

Thư mục này chứa các tài nguyên ảnh gốc (source assets) chưa qua đóng gói hoặc tối ưu hóa cho runtime.
Thư mục có file `.gdignore` để Godot Engine bỏ qua hoàn toàn, không đưa các file strip dung lượng lớn này vào bản build xuất bản game.

## Nội dung:
1. `player_idle_strip.png`: Strip gốc 48 frame Idle, kích thước 24.576 x 680 px (mỗi frame 512 x 680 px).
2. `player_run_strip.png`: Strip 16 frame Run liên tiếp (frame 28-43 của `assets/run.mp4`), kích thước 8.192 x 680 px (mỗi frame 512 x 680 px). Frame 44 gần trùng frame 28 nên điểm nối vòng lặp mượt; từng frame được lật để nhân vật mặc định nhìn sang phải.
3. `repack_sprites.ps1`: PowerShell script tự động cắt các frame từ strip gốc và đóng gói lại thành Sprite Atlas nhỏ gọn trong `res://assets/sprites/player/`:
   - `player_idle_atlas.png`: 2048 x 2040 px (8 cột x 6 hàng, frame 256 x 340 px).
   - `player_run_atlas.png`: 1024 x 1360 px (4 cột x 4 hàng, frame 256 x 340 px).

## Cách tái tạo Atlas từ Strip:
Khi thay thế ảnh strip mới, mở PowerShell và chạy:
```powershell
powershell -ExecutionPolicy Bypass -File source_assets\repack_sprites.ps1
```
Script sẽ tự động sinh lại 2 file atlas tại `assets/sprites/player/` tương thích 100% với cấu hình `AnimationPlayer` trong `player.tscn`.
