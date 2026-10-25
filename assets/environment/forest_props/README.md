# Forest props selected from assets/asset

Prepared with the built-in imagegen tool in background-extraction mode. Original JPGs are preserved. The transparent PNGs are referenced by `src/world/forest_png_dressing.tscn`; they are background decorations, not additional walkable surfaces.

| Prepared PNG | Original image |
| --- | --- |
| mushroom_log.png | assets/asset/3b6256a5fb00b2c3ae5770e3782b1f90.jpg |
| mossy_rocks_bird.png | assets/asset/67f3566e63d6d98ac38d47b9688ebc7b.jpg |
| woodland_sign.png | assets/asset/7fc5023b8d45b9d270406c041f34c5d5.jpg |

Extraction prompt: preserve the complete original illustrated object, materials, colors, delicate foliage and any artist attribution; remove only the plain background and broad background rays; genuine RGBA transparency, no new objects or writing, no cropped object, small transparent margin.

The existing `assets/asset/Mossy Grass Terrain Strip.png` is used directly by `noctis_terrain.gd`, in separate patches clipped to each horizontal segment of the same contour used for collision. The doorway is kept clear.

Move, scale or hide individual decorations by editing `forest_png_dressing.tscn`. PNG base anchors are set through each sprite's offset, so its node position corresponds to the terrain baseline. World lighting and day/night modulation continue to affect these sprites.
