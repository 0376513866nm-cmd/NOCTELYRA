import bpy
import math
from mathutils import Quaternion, Vector


# Run this file from Blender's Scripting workspace while the character file is open.
# It creates an in-place Rigify run cycle and does not save the .blend automatically.
ACTION_NAME = "Run_InPlace_Loop"
FPS = 24
START_FRAME = 1
END_FRAME = 16
LOOP_KEY = 17


def find_rig():
    preferred = bpy.data.objects.get("rig")
    if preferred and preferred.type == "ARMATURE" and preferred.data.get("rig_id"):
        return preferred
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE" and obj.data.get("rig_id"):
            return obj
    raise RuntimeError("Could not find a generated Rigify control rig")


def require_bone(rig, name):
    bone = rig.pose.bones.get(name)
    if bone is None:
        raise RuntimeError(f"Missing Rigify control bone: {name}")
    return bone


def set_rotation(bone, base, axis, degrees):
    bone.rotation_mode = "QUATERNION"
    bone.rotation_quaternion = base @ Quaternion(Vector(axis), math.radians(degrees))


def key_bone(bone, frame):
    bone.keyframe_insert("location", frame=frame, group=bone.name)
    bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone.name)


def main():
    scene = bpy.context.scene
    rig = find_rig()

    scene.render.fps = FPS
    scene.frame_start = START_FRAME
    scene.frame_end = END_FRAME
    scene.frame_preview_start = START_FRAME
    scene.frame_preview_end = END_FRAME

    if rig.animation_data is None:
        rig.animation_data_create()

    previous = bpy.data.actions.get(ACTION_NAME)
    if previous:
        if rig.animation_data.action == previous:
            rig.animation_data.action = None
        bpy.data.actions.remove(previous)

    action = bpy.data.actions.new(ACTION_NAME)
    action.use_fake_user = True
    rig.animation_data.action = action

    names = (
        "root", "torso", "hips", "chest", "spine_fk.002", "spine_fk.003",
        "neck", "head", "shoulder.L", "shoulder.R",
        "upper_arm_fk.L", "forearm_fk.L", "hand_fk.L",
        "upper_arm_fk.R", "forearm_fk.R", "hand_fk.R",
        "thigh_fk.L", "shin_fk.L", "foot_fk.L", "toe_fk.L",
        "thigh_fk.R", "shin_fk.R", "foot_fk.R", "toe_fk.R",
    )
    bones = {name: require_bone(rig, name) for name in names}

    # This rig uses Rigify's standard switch: 0 = IK, 1 = FK.
    # The run cycle keys FK controls, so the switch must be set to 1.
    switch_bones = {
        name: require_bone(rig, name)
        for name in (
            "upper_arm_parent.L", "upper_arm_parent.R",
            "thigh_parent.L", "thigh_parent.R",
        )
    }
    for bone in switch_bones.values():
        bone["IK_FK"] = 1.0
        bone.keyframe_insert(data_path='["IK_FK"]', frame=START_FRAME, group=bone.name)
        bone.keyframe_insert(data_path='["IK_FK"]', frame=LOOP_KEY, group=bone.name)

    base_location = {name: bone.location.copy() for name, bone in bones.items()}
    base_rotation = {name: bone.rotation_quaternion.copy() for name, bone in bones.items()}

    # Eight samples plus a duplicate loop key give a compact, editable run cycle.
    for sample in range(9):
        frame = START_FRAME + sample * 2
        phase = sample * math.pi / 4.0
        stride = math.sin(phase)
        stride_velocity = math.cos(phase)
        double_step = math.cos(phase * 2.0)
        bounce = (1.0 - double_step) * 0.5
        side_shift = math.sin(phase * 2.0)

        for name, bone in bones.items():
            bone.location = base_location[name]
            bone.rotation_mode = "QUATERNION"
            bone.rotation_quaternion = base_rotation[name]

        # Center of mass: forward athletic lean, two vertical pulses per cycle.
        bones["torso"].location.z += 0.026 * bounce
        bones["hips"].location.x += 0.010 * side_shift
        bones["hips"].location.z -= 0.008 * double_step
        set_rotation(bones["hips"], base_rotation["hips"], (0, 1, 0), 3.0 * side_shift)
        set_rotation(bones["chest"], base_rotation["chest"], (1, 0, 0), -8.0 + 1.8 * bounce)
        set_rotation(
            bones["spine_fk.002"], base_rotation["spine_fk.002"],
            (0, 0, 1), -3.0 * side_shift,
        )
        set_rotation(
            bones["spine_fk.003"], base_rotation["spine_fk.003"],
            (1, 0, 0), -4.0 + 1.2 * bounce,
        )
        set_rotation(bones["neck"], base_rotation["neck"], (1, 0, 0), 4.5 - bounce)
        set_rotation(bones["head"], base_rotation["head"], (0, 0, 1), 1.2 * side_shift)

        # Legs: opposing stride with extra knee flex during recovery.
        left_knee = 14.0 + 39.0 * max(0.0, -stride_velocity)
        right_knee = 14.0 + 39.0 * max(0.0, stride_velocity)
        set_rotation(bones["thigh_fk.L"], base_rotation["thigh_fk.L"], (1, 0, 0), 38.0 * stride)
        set_rotation(bones["thigh_fk.R"], base_rotation["thigh_fk.R"], (1, 0, 0), -38.0 * stride)
        set_rotation(bones["shin_fk.L"], base_rotation["shin_fk.L"], (1, 0, 0), left_knee)
        set_rotation(bones["shin_fk.R"], base_rotation["shin_fk.R"], (1, 0, 0), right_knee)
        set_rotation(bones["foot_fk.L"], base_rotation["foot_fk.L"], (1, 0, 0), -18.0 * stride - 8.0 * bounce)
        set_rotation(bones["foot_fk.R"], base_rotation["foot_fk.R"], (1, 0, 0), 18.0 * stride - 8.0 * bounce)
        set_rotation(bones["toe_fk.L"], base_rotation["toe_fk.L"], (1, 0, 0), 8.0 * max(0.0, stride_velocity))
        set_rotation(bones["toe_fk.R"], base_rotation["toe_fk.R"], (1, 0, 0), 8.0 * max(0.0, -stride_velocity))

        # Arms counter-swing against the legs; elbows stay bent for a game-ready silhouette.
        set_rotation(bones["shoulder.L"], base_rotation["shoulder.L"], (0, 0, 1), -3.0 * stride)
        set_rotation(bones["shoulder.R"], base_rotation["shoulder.R"], (0, 0, 1), 3.0 * stride)
        set_rotation(bones["upper_arm_fk.L"], base_rotation["upper_arm_fk.L"], (1, 0, 0), -44.0 * stride)
        set_rotation(bones["upper_arm_fk.R"], base_rotation["upper_arm_fk.R"], (1, 0, 0), 44.0 * stride)
        set_rotation(bones["forearm_fk.L"], base_rotation["forearm_fk.L"], (1, 0, 0), 52.0 + 9.0 * stride_velocity)
        set_rotation(bones["forearm_fk.R"], base_rotation["forearm_fk.R"], (1, 0, 0), -52.0 - 9.0 * stride_velocity)
        set_rotation(bones["hand_fk.L"], base_rotation["hand_fk.L"], (0, 0, 1), 5.0 * stride)
        set_rotation(bones["hand_fk.R"], base_rotation["hand_fk.R"], (0, 0, 1), -5.0 * stride)

        for bone in bones.values():
            key_bone(bone, frame)

    # Auto-clamped Bezier curves avoid overshoot while keeping the loop smooth.
    if hasattr(action, "fcurves"):
        for curve in action.fcurves:
            for point in curve.keyframe_points:
                point.interpolation = "BEZIER"
                point.handle_left_type = "AUTO_CLAMPED"
                point.handle_right_type = "AUTO_CLAMPED"

    for marker in tuple(scene.timeline_markers):
        if marker.name in {"RUN_START", "RUN_LOOP"}:
            scene.timeline_markers.remove(marker)
    scene.timeline_markers.new("RUN_START", frame=START_FRAME)
    scene.timeline_markers.new("RUN_LOOP", frame=LOOP_KEY)

    scene.frame_set(START_FRAME)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    print(
        f"Created {ACTION_NAME}: frames {START_FRAME}-{END_FRAME}, "
        f"{FPS} FPS, duplicate loop key at {LOOP_KEY}. Save the .blend when ready."
    )


main()
