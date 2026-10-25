# Modular bamboo forest

These resources reference the supplied PNG files directly. No original image is changed and no replacement artwork is generated.

- `rock_00.tres` through `rock_23.tres`: individually clipped AtlasTexture regions from `Mossy Rock Collection Spritesheet.png`.
- `bamboo_green_a.tres`, `bamboo_green_b.tres`, `bamboo_dry.tres`: stalks from the Photoroom bamboo sheet.
- `bamboo_leaves_a.tres`, `bamboo_leaves_b.tres`: reusable leaf sprays from that sheet.
- The cottage uses `Rustic Bamboo Cottage with Lush Vines.png` directly.

## In Godot

- Move or scale placed rocks in `src/world/forest_rock_dressing.tscn`. They are scenery behind the playable lane, not new floating platforms.
- Open `src/world/bamboo_cottage.tscn` to adjust the house sprite or its lights. The house base is aligned to the starting terrain at y=632.
- In `src/world/bamboo_grove.tscn`, select a bamboo clump (Kind = Bamboo clump) and change Variant to get a different deterministic arrangement of 4–7 culms and leaf sprays. Scale and move the complete clump normally.
- The current forest uses the newer supplied stem and watercolor branch in `assets/environment/ink_bamboo/`, assembled into two textured meshes per depth layer. Each layer keeps its parallax speed; the closest clumps also sway lightly.
- The five bamboo AtlasTexture resources in this folder are older alternatives; the six current editable parts are in `ink_bamboo/`.

Regenerate atlas regions with `python tools/build_forest_atlas_resources.py`.
