# Tre từ ảnh người dùng

- `culm_source.png`: bản sao nguyên ảnh thân tre đã cung cấp.
- `branch_source.png`: bản sao nguyên ảnh cành đã tách nền; màu ở pixel trong suốt không phải nội dung hiển thị.
- `stem_a/b/c.tres`: ba đoạn thân có đốt để ghép nối.
- `branch_long/tip/middle.tres`: cắt UV cành dài, ngọn và giữa cành, bỏ cuống trống phía dưới.

Kéo tài nguyên .tres vào Texture của Sprite2D để ghép thủ công. Khi lật cành, cần giữ gốc cành trùng với đốt thân.

Trong game, src/world/bamboo_atlas_brush.gd ghép các vùng ảnh này thành hai mesh cho mỗi lớp, giữ parallax và rung nhẹ của bụi tre. Chọn bụi tre trong bamboo_grove.tscn rồi đổi Variant để đổi cách ghép.

Ảnh gốc và các ảnh thử nghiệm cũ được giữ nguyên. Các ảnh bamboo_var và bamboo_atlas_variants không được renderer mới sử dụng.
