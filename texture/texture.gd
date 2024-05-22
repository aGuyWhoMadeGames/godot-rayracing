@tool
extends Node3D

#attemped compute shader based version

@export var reload = false:
	set(_v):
		RenderingServer.call_on_render_thread(init_shader)
		camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()

var rd:RenderingDevice

var shader : RID
var pipeline : RID

var texture_rd:RID
var texture_set:RID

var texture:Texture2DRD

var camera:Camera3D

func _ready() -> void:
	RenderingServer.call_on_render_thread(init_shader)
	
	camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	
	var material:ShaderMaterial = $MeshInstance3D.material_override
	texture = material.get_shader_parameter("texture_albedo")

func _process(_delta: float) -> void:
	RenderingServer.call_on_render_thread(render_process)
	
	if texture:
		texture.texture_rd_rid = texture_rd


func init_shader():
	rd = RenderingServer.get_rendering_device()
	
	# Create our shader.
	var shader_file = load("res://texture/texture.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

	# Create our textures to manage our wave.
	var tf : RDTextureFormat = RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = 512
	tf.height = 512
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	
	# Create our texture.
	texture_rd = rd.texture_create(tf, RDTextureView.new(), [])

	# Make sure our textures are cleared.
	rd.texture_clear(texture_rd, Color(0, 0, 0, 0), 0, 1, 0, 1)

	# Now create our uniform set so we can use these textures in our shader.
	texture_set = _create_uniform_set(texture_rd)

@warning_ignore("shadowed_variable")
func _create_uniform_set(texture_rd : RID) -> RID:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(texture_rd)
	# Even though we're using 3 sets, they are identical, so we're kinda cheating.
	return rd.uniform_set_create([uniform], shader, 0)

func render_process():
	var push_constant : PackedFloat32Array = PackedFloat32Array()
	
	var camBasis = camera.global_basis
	push_constant.push_back(camBasis[0][0])
	push_constant.push_back(camBasis[0][1])
	push_constant.push_back(camBasis[0][2])
	push_constant.push_back(0.0)
	push_constant.push_back(camBasis[1][0])
	push_constant.push_back(camBasis[1][1])
	push_constant.push_back(camBasis[1][2])
	push_constant.push_back(0.0)
	push_constant.push_back(camBasis[2][0])
	push_constant.push_back(camBasis[2][1])
	push_constant.push_back(camBasis[2][2])
	push_constant.push_back(0.0)
	
	var camPos = camera.global_position
	push_constant.push_back(camPos.x)
	push_constant.push_back(camPos.y)
	push_constant.push_back(camPos.z)
	push_constant.push_back(0.0)
	
	var projection = camera.get_camera_projection().inverse()
	
	push_constant.push_back(projection[0][0])
	push_constant.push_back(projection[0][1])
	push_constant.push_back(projection[0][2])
	push_constant.push_back(projection[0][3])
	push_constant.push_back(projection[1][0])
	push_constant.push_back(projection[1][1])
	push_constant.push_back(projection[1][2])
	push_constant.push_back(projection[1][3])
	push_constant.push_back(projection[2][0])
	push_constant.push_back(projection[2][1])
	push_constant.push_back(projection[2][2])
	push_constant.push_back(projection[2][3])
	push_constant.push_back(projection[3][0])
	push_constant.push_back(projection[3][1])
	push_constant.push_back(projection[3][2])
	push_constant.push_back(projection[3][3])
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, texture_set, 0)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, 64, 64, 1)
	rd.compute_list_end()
