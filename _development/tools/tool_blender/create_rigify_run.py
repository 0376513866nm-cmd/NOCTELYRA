import bpy
import math
from mathutils import Vector


# Run in Blender's Scripting workspace while the character file is open.
# Creates a conservative in-place run cycle using Rigify IK targets.
# The script does not save the .blend automatically.
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


def set_matrix_translation(bone, base_matrix, offset):
    """Move an IK control in armature space without changing its orientation."""
    matrix = base_matrix.copy()
    matrix.translation = base_matrix.translation + Vector(offset)
    bone.matrix = matrix


def key_transform(bone, frame):
    bone.keyframe_insert("location", frame=frame, group=bone.name)
    if bone.rotation_mode == "QUATERNION":
        bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone.name)
    else:
        bone.keyframe_insert("rotation_euler", frame=frame, group=bone.name)
    bone.keyframe_insert("scale", frame=frame, group=bone.name)


def main():
    scene = bpy.context.scene
    rig = find_rig()

    scene.render.fps = FPS
    scene.frame_start = START_FRAME
    scene.frame_end = END_FRAME
    scene.frame_preview_start = START_FRAME
    scene.frame_preview_end = END_FRAME

    # Return to a neutral pose before recording the replacement action.
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = None

    # Clear channel values left behind by the previous broken action. Without
    # this step Blender can keep the deformed frame as the new reference pose.
    for bone in rig.pose.bones:
        if bone.name.startswith(("ORG-", "DEF-", "MCH-")):
            continue
        bone.location = (0.0, 0.0, 0.0)
        bone.scale = (1.0, 1.0, 1.0)
        if bone.rotation_mode == "QUATERNION":
            bone.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        elif bone.rotation_mode == "AXIS_ANGLE":
            bone.rotation_axis_angle = (0.0, 0.0, 1.0, 0.0)
        else:
            bone.rotation_euler = (0.0, 0.0, 0.0)
    scene.frame_set(START_FRAME)
    bpy.context.view_layer.update()

    old_action = bpy.data.actions.get(ACTION_NAME)
    if old_action:
        bpy.data.actions.remove(old_action)
    action = bpy.data.actions.new(ACTION_NAME)
    action.use_fake_user = True
    rig.animation_data.action = action

    torso = require_bone(rig, "torso")
    hips = require_bone(rig, "hips")
    chest = require_bone(rig, "chest")
    head = require_bone(rig, "head")
    hand_l = require_bone(rig, "hand_ik.L")
    hand_r = require_bone(rig, "hand_ik.R")
    foot_l = require_bone(rig, "foot_ik.L")
    foot_r = require_bone(rig, "foot_ik.R")

    controls = (torso, hips, chest, head, hand_l, hand_r, foot_l, foot_r)
    base_location = {bone.name: bone.location.copy() for bone in controls}
    base_matrix = {bone.name: bone.matrix.copy() for bone in controls}

    # 0 selects IK. Unlike the broken FK version, this script animates the
    # hand and foot IK targets themselves, so they do not remain pinned.
    switches = (
        require_bone(rig, "upper_arm_parent.L"),
        require_bone(rig, "upper_arm_parent.R"),
        require_bone(rig, "thigh_parent.L"),
        require_bone(rig, "thigh_parent.R"),
    )
    for bone in switches:
        bone["IK_FK"] = 0.0
        bone.keyframe_insert(data_path='["IK_FK"]', frame=START_FRAME, group=bone.name)
        bone.keyframe_insert(data_path='["IK_FK"]', frame=LOOP_KEY, group=bone.name)
        if "pole_vector" in bone:
            bone["pole_vector"] = False
            bone.keyframe_insert(data_path='["pole_vector"]', frame=START_FRAME, group=bone.name)
            bone.keyframe_insert(data_path='["pole_vector"]', frame=LOOP_KEY, group=bone.name)

    # Eight evenly spaced poses plus frame 17 duplicating frame 1.
    for sample in range(9):
        frame = START_FRAME + sample * 2
        phase = sample * math.pi / 4.0
        stride = math.cos(phase)
        swing_speed = math.sin(phase)
        double_step = math.cos(phase * 2.0)
        side_shift = math.sin(phase * 2.0)
        bounce = (1.0 - double_step) * 0.5

        left_foot_lift = 0.18 * max(0.0, -swing_speed)
        right_foot_lift = 0.18 * max(0.0, swing_speed)

        for bone in (torso, hips, chest, head):
            bone.location = base_location[bone.name]

        torso.location.z += 0.020 * bounce
        hips.location.x += 0.006 * side_shift
        hips.location.z -= 0.004 * double_step
        chest.location.z += 0.004 * bounce
        head.location.z -= 0.003 * bounce

        # Armature-space offsets: this character faces -Y, so negative Y is
        # forward. The stance foot travels toward +Y while the lifted foot
        # recovers toward -Y.
        set_matrix_translation(
            foot_l, base_matrix[foot_l.name],
            (0.0, -0.27 * stride, left_foot_lift),
        )
        set_matrix_translation(
            foot_r, base_matrix[foot_r.name],
            (0.0, 0.27 * stride, right_foot_lift),
        )
        set_matrix_translation(
            hand_l, base_matrix[hand_l.name],
            (0.0, 0.20 * stride, 0.045 * max(0.0, stride)),
        )
        set_matrix_translation(
            hand_r, base_matrix[hand_r.name],
            (0.0, -0.20 * stride, 0.045 * max(0.0, -stride)),
        )

        bpy.context.view_layer.update()
        for bone in controls:
            key_transform(bone, frame)

    # Smooth curves without overshoot.
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
        f"{FPS} FPS, duplicate loop key at {LOOP_KEY}. Save when satisfied."
    )


main()
