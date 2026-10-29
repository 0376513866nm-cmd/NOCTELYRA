import bpy
import math
import os
import sys
from mathutils import Vector


def look_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def main():
    output_dir = os.path.abspath(sys.argv[sys.argv.index("--output-dir") + 1])
    os.makedirs(output_dir, exist_ok=True)
    scene = bpy.context.scene

    meshes = [obj for obj in scene.objects if obj.type == "MESH" and obj.visible_get()]
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    low = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    high = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    center = (low + high) * 0.5
    height = max(high.z - low.z, 0.1)

    camera_data = bpy.data.cameras.new("IdlePreviewCamera")
    camera = bpy.data.objects.new("IdlePreviewCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.lens = 58
    camera.location = center + Vector((0.0, -height * 2.25, height * 0.05))
    look_at(camera, center + Vector((0, 0, height * 0.02)))

    world = scene.world or bpy.data.worlds.new("IdlePreviewWorld")
    scene.world = world
    world.color = (0.025, 0.025, 0.035)

    for name, location, energy, size in (
        ("Key", center + Vector((-height, -height, height * 1.3)), 1000, 4.0),
        ("Fill", center + Vector((height, -height * 0.3, height * 0.8)), 650, 3.0),
        ("Rim", center + Vector((0, height, height * 1.2)), 850, 3.0),
    ):
        light_data = bpy.data.lights.new(name, "AREA")
        light_data.energy = energy
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        scene.collection.objects.link(light)
        light.location = location
        look_at(light, center)

    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False

    span = scene.frame_end - scene.frame_start
    sample_frames = tuple(
        scene.frame_start + round(span * fraction)
        for fraction in (0.0, 0.25, 0.5, 0.75)
    )
    for frame in sample_frames:
        scene.frame_set(frame)
        scene.render.filepath = os.path.join(output_dir, f"idle_{frame:02d}.png")
        bpy.ops.render.render(write_still=True)
        print(f"RENDERED {scene.render.filepath}")

    frames_dir = os.path.join(output_dir, "frames")
    os.makedirs(frames_dir, exist_ok=True)
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = os.path.join(frames_dir, "idle_")
    bpy.ops.render.render(animation=True)
    print(f"RENDERED {scene.render.filepath}")


if __name__ == "__main__":
    main()
