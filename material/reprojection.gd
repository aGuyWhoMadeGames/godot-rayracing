@tool
extends MeshInstance3D

var prevView:Transform3D = Transform3D()

func _process(_delta: float) -> void:
	var material:ShaderMaterial = material_override
	var camera:Camera3D
	if Engine.is_editor_hint():
		camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
		material.set_shader_parameter("prevView",camera.get_camera_transform().inverse())
	else:
		
		camera = get_viewport().get_camera_3d()
		material.set_shader_parameter("prevView",prevView)
		prevView = camera.get_camera_transform().inverse()
