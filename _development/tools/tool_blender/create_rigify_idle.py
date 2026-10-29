import bpy
import math
import os
import sys
from mathutils import Quaternion, Vector


RIG_NAME = "rig"
ACTION_NAME = "Idle_Subtle_Loop"
FPS = 24
START_FRAME = 1
END_FRAME = 48
LOOP_KEY = 49


def output_path():
    marker = "--output"
    if marker in sys.argv:
        index = sys.argv.index(marker)
        return os.path.abspath(sys.argv[index + 1])
    return os.path.abspath("boy-toc-nau_idle.blend")


def require_bone(rig, name):
    bone = rig.pose.bones.get(name)
    if bone is None:
        raise RuntimeError(f"Rigify control bone not found: {name}")
    return bone


def set_quaternion_delta(bone, base_quaternion, axis, angle):
    bone.rotation_mode = "QUATERNION"
    bone.rotation_quaternion = base_quaternion @ Quaternion(axis, angle)


def key_transform(bone, frame, location=True, rotation=True, scale=False):
    if location:
        bone.keyframe_insert("location", frame=frame, group=bone.name)
    if rotation:
        bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone.name)
    if scale:
        bone.keyframe_insert("scale", frame=frame, group=bone.name)


def main():
    scene = bpy.context.scene
    rig = bpy.data.objects.get(RIG_NAME)
    if rig is None or rig.type != "ARMATURE":
        raise RuntimeError(f"Armature '{RIG_NAME}' was not found")
    if not rig.data.get("rig_id"):
        raise RuntimeError("The target armature does not appear to be a generated Rigify rig")

    scene.render.fps = FPS
    scene.frame_start = START_FRAME
    scene.frame_end = END_FRAME
    scene.frame_preview_start = START_FRAME
    scene.frame_preview_end = END_FRAME

    if rig.animation_data is None:
        rig.animation_data_create()
    old_action = bpy.data.actions.get(ACTION_NAME)
    if old_action:
        bpy.data.actions.remove(old_action)
    action = bpy.data.actions.new(ACTION_NAME)
    action.use_fake_user = True
    rig.animation_data.action = action

    controls = {
        name: require_bone(rig, name)
        for name in (
            "torso", "hips", "chest", "spine_fk.002", "spine_fk.003",
            "neck", "head", "shoulder.L", "shoulder.R",
            "upper_arm_fk.L", "upper_arm_fk.R", "forearm_fk.L", "forearm_fk.R",
        )
    }
    base_location = {name: bone.location.copy() for name, bone in controls.items()}
    base_rotation = {name: bone.rotation_quaternion.copy() for name, bone in controls.items()}

    # Five samples make a clean two-second loop. Frame 49 duplicates frame 1;
    # the scene ends on 48 so a game exporter does not include the duplicate.
    samples = (
        (1, 0.0),
        (13, math.pi / 2.0),
        (25, math.pi),
        (37, math.pi * 1.5),
        (49, math.pi * 2.0),
    )

    for frame, phase in samples:
        breathe = math.sin(phase)
        drift = math.sin(phase * 0.5)
        counter = math.cos(phase)

        for name, bone in controls.items():
            bone.location = base_location[name]
            bone.rotation_mode = "QUATERNION"
            bone.rotation_quaternion = base_rotation[name]

        controls["torso"].location.z += 0.0040 * breathe
        controls["hips"].location.x += 0.0020 * drift
        controls["hips"].location.z -= 0.0015 * breathe

        set_quaternion_delta(
            controls["hips"], base_rotation["hips"], Vector((0, 1, 0)),
            math.radians(0.7) * drift,
        )
        set_quaternion_delta(
            controls["chest"], base_rotation["chest"], Vector((1, 0, 0)),
            math.radians(1.0) * breathe,
        )
        set_quaternion_delta(
            controls["spine_fk.002"], base_rotation["spine_fk.002"], Vector((0, 0, 1)),
            math.radians(0.45) * drift,
        )
        set_quaternion_delta(
            controls["spine_fk.003"], base_rotation["spine_fk.003"], Vector((1, 0, 0)),
            math.radians(0.55) * breathe,
        )
        set_quaternion_delta(
            controls["neck"], base_rotation["neck"], Vector((1, 0, 0)),
            math.radians(-0.35) * breathe,
        )
        set_quaternion_delta(
            controls["head"], base_rotation["head"], Vector((0, 0, 1)),
            math.radians(0.45) * counter,
        )

        # A very small asymmetric shoulder/arm response prevents a mannequin-like loop.
        set_quaternion_delta(
            controls["shoulder.L"], base_rotation["shoulder.L"], Vector((1, 0, 0)),
            math.radians(0.35) * breathe,
        )
        set_quaternion_delta(
            controls["shoulder.R"], base_rotation["shoulder.R"], Vector((1, 0, 0)),
            math.radians(0.25) * breathe,
        )
        set_quaternion_delta(
            controls["upper_arm_fk.L"], base_rotation["upper_arm_fk.L"], Vector((0, 0, 1)),
            math.radians(0.35) * drift,
        )
        set_quaternion_delta(
            controls["upper_arm_fk.R"], base_rotation["upper_arm_fk.R"], Vector((0, 0, 1)),
            math.radians(-0.35) * drift,
        )
        set_quaternion_delta(
            controls["forearm_fk.L"], base_rotation["forearm_fk.L"], Vector((1, 0, 0)),
            math.radians(0.25) * counter,
        )
        set_quaternion_delta(
            controls["forearm_fk.R"], base_rotation["forearm_fk.R"], Vector((1, 0, 0)),
            math.radians(-0.20) * counter,
        )

        for bone in controls.values():
            key_transform(bone, frame)

    # Smooth interpolation, with a constant-speed phase through each quarter-cycle.
    if hasattr(action, "fcurves"):
        for curve in action.fcurves:
            for point in curve.keyframe_points:
                point.interpolation = "BEZIER"
                point.handle_left_type = "AUTO_CLAMPED"
                point.handle_right_type = "AUTO_CLAMPED"

    scene.timeline_markers.new("IDLE_START", frame=START_FRAME)
    scene.timeline_markers.new("IDLE_LOOP", frame=LOOP_KEY)
    scene.frame_set(START_FRAME)

    path = output_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path, check_existing=False)
    print(
        f"NOCTELYRA_IDLE_CREATED path={path} action={ACTION_NAME} "
        f"fps={FPS} range={START_FRAME}-{END_FRAME} loop_key={LOOP_KEY}"
    )


if __name__ == "__main__":
    main()
