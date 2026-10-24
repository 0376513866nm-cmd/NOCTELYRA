# Bamboo map FPS benchmark — 2026-10-24

Measured in a real rendered Godot 4.3 window on the NVIDIA GeForce RTX 3050 Laptop GPU, 1440 × 720. VSync and the FPS cap were disabled only inside the benchmark process. Each case warms up for 1.5 seconds and samples for 3.5 seconds while the camera pans. Gameplay physics, characters, particles and lighting remain active.

## Same-renderer comparison (OpenGL Compatibility)

| Scene | Before FPS | After FPS | Before frame time | After frame time | Before draw calls | After draw calls | After p99 frame time |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Home, day, zoom 1.0 | 11.3 | 658.0 | 88.79 ms | 1.52 ms | 19,731 | 151 | 2.46 ms |
| Forest, day, zoom 1.0 | 11.7 | 625.7 | 85.83 ms | 1.60 ms | 19,659 | 134 | 2.84 ms |
| Wide view, night, zoom 0.6 | 11.2 | 590.0 | 89.28 ms | 1.69 ms | 20,049 | 179 | 2.42 ms |

Before optimization, hiding the bamboo backdrop increased home FPS from 11.3 to 125.8; disabling lights alone left it at 11.5. This isolated the excessive individual canvas drawing commands as the main bottleneck.

The fix batches colored canvas shapes into retained ArrayMesh geometry. Static scenery builds its mesh when redrawn; moving bamboo props reuse their geometry through node transforms. Falling leaves remain animated. The scene still uses editable procedural shapes, with no image baking or resolution reduction.

Forward+ was also checked separately: 1006.9 FPS at home, 1022.1 FPS in the forest and 998.1 FPS in the wide night view. These are uncapped throughput measurements, not display refresh rates.

## Validation

- 371 vertical ground raycasts: zero mismatch between visible contour and collision.
- Home healing, NPC interaction, loot sizes and day/night lantern behavior passed.
- Existing day/night, grounding, sanctuary and pet regression scripts passed.
- Rendered screenshots inspected after optimization.

Raw measurements: `bamboo_fps_baseline.json`, `bamboo_fps_optimized_final.json`, `bamboo_fps_optimized_forward_plus.json` in this directory.

Re-run from PowerShell:

```powershell
& 'D:\program\Godot\Godot_v4.3-stable_win64_console.exe' --path 'D:\project\game\NOCTELYRA' --rendering-method gl_compatibility --resolution 1440x720 --script 'res://tools/benchmark_bamboo_map.gd' -- repeat
```

The runner rejects headless execution and missing generated artwork, so an empty or failed scene cannot produce a misleading successful report.
