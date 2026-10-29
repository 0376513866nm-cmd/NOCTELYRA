import bpy
import json


def main():
    report = {
        "file": bpy.data.filepath,
        "scene": bpy.context.scene.name,
        "fps": bpy.context.scene.render.fps,
        "frame_start": bpy.context.scene.frame_start,
        "frame_end": bpy.context.scene.frame_end,
        "armatures": [],
    }

    for obj in bpy.data.objects:
        if obj.type != "ARMATURE":
            continue

        control_markers = (
            "root", "torso", "chest", "hips", "spine_fk", "neck", "head",
            "upper_arm_fk", "forearm_fk", "hand_fk", "hand_ik",
            "thigh_fk", "shin_fk", "foot_fk", "foot_ik", "toe",
        )
        armature = {
            "name": obj.name,
            "data_name": obj.data.name,
            "rig_id": obj.data.get("rig_id"),
            "visible": obj.visible_get(),
            "bone_count": len(obj.pose.bones),
            "control_bones": [],
        }
        for bone in obj.pose.bones:
            if bone.name.startswith(("ORG-", "DEF-", "MCH-")):
                continue
            if not any(marker in bone.name.lower() for marker in control_markers):
                continue
            armature["control_bones"].append(
                {
                    "name": bone.name,
                    "parent": bone.parent.name if bone.parent else None,
                    "rotation_mode": bone.rotation_mode,
                    "constraints": [constraint.type for constraint in bone.constraints],
                    "custom_properties": [
                        key for key in bone.keys() if key != "_RNA_UI"
                    ],
                }
            )
        report["armatures"].append(armature)

    print("NOCTELYRA_RIG_REPORT_BEGIN")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print("NOCTELYRA_RIG_REPORT_END")


if __name__ == "__main__":
    main()
