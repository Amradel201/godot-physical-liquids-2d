@tool
@icon("uid://cifkqtawd8mq0")
class_name Liquid
extends Area2D

@export_enum("Custom", "Water", "Lava") var preset = "Custom":
	set(value):
		preset = value
		match value:
			"Water":
				_apply_water_preset()
			"Lava":
				_apply_lava_preset()
			"Custom":
				pass
		if Engine.is_editor_hint():
			notify_property_list_changed()

@export_category("Appearance")
@export var color :Color = Color(0.0, 0.246, 0.77, 1.0):
	set(val):
		color=val
		polygon.color = val
@export var height := 200.0:
	set(val):
		height= val
		collision_rect.size.y = val
		collision_shape.position.y= val/2
@export var width := 500.0:
	set(val):
		width = val
		collision_rect.size.x = val
		collision_shape.position.x = val/2
		spring_count = int(val /17)
		heights.resize(spring_count)
		velocities.resize(spring_count)
		heights.fill(0.0)
		velocities.fill(0.0)


@export_category("Ambient Waves")
@export var pass_waves := true
@export var wave_speed := 2.0
@export var wave_frequency := 0.3
@export var wave_amplitude := 0.05

@export_category("Splash")
@export_tool_button("Test Splash") var splash_func = test_splash
@export_range(0.003,0.1,0.001) var stiffness := 0.007
@export_range(0.001,1.0) var damping := 0.03
@export var power := 0.03
@export var spread := 0.003


var spring_count := 60

var collision_shape = CollisionShape2D.new()
var collision_rect = RectangleShape2D.new()
var polygon = Polygon2D.new()

var time := 0.0 


var heights := PackedFloat32Array()
var velocities := PackedFloat32Array()
var target_height := 0.0

func _enter_tree() -> void:
	spring_count = width/17
	
	polygon.color = color
	add_child(polygon)
	
	collision_rect.size = Vector2(width, height)
	collision_shape.shape =collision_rect
	collision_shape.position = Vector2(width, height) /2
	collision_shape.hide()
	add_child(collision_shape)

func _ready():
	spring_count = int(spring_count * scale.x)
	
	heights.resize(spring_count)
	velocities.resize(spring_count)
	heights.fill(0.0)
	velocities.fill(0.0)
	
	body_entered.connect(_on_body_entered)



func _physics_process(delta):
	time+= delta
	
	if pass_waves:
		for i in range(spring_count):
			var wave_force = sin(time * wave_speed + i * wave_frequency) * wave_amplitude
			velocities[i] += wave_force

	for i in range(spring_count):
		var displacement = heights[i] - target_height
		velocities[i] += -stiffness * displacement - damping * velocities[i]
		heights[i] += velocities[i]
		
	var left_deltas := PackedFloat32Array()
	var right_deltas := PackedFloat32Array()
	left_deltas.resize(spring_count)
	right_deltas.resize(spring_count)
	left_deltas.fill(0.0)
	right_deltas.fill(0.0)
	
	for passes in range(8):
		for i in range(spring_count):
			if i > 0:
				left_deltas[i] = spread * (heights[i] - heights[i - 1])
				velocities[i - 1] += left_deltas[i]
			if i < spring_count - 1:
				right_deltas[i] = spread * (heights[i] - heights[i + 1])
				velocities[i +1] += right_deltas[i]
				
		for i in range(spring_count):
			if i > 0:
				heights[i- 1] += left_deltas[i]
			if i < spring_count - 1:
				heights[i+ 1] += right_deltas[i]
				
	draw_water()

func draw_water():
	var points = PackedVector2Array()
	var step = width/(spring_count - 1)
	
	for i in range(spring_count):
		points.append(Vector2(i * step, heights[i]))
		
	points.append(Vector2(width, height))
	points.append(Vector2(0, height))
	
	polygon.polygon = points

func splash(index: int, force: float):
	if index >= 0 and index < spring_count:
		velocities[index] = force

func _on_body_entered(body: Node2D):
	if "velocity" in body:
		var local_x = to_local(body.global_position).x
		_start_splash(local_x, body.velocity.y)

func _start_splash(posx, velocity_y):
	var step= width / (spring_count - 1)
	var index = int(round(posx / step))
	
	var fall_force = 30.0
	fall_force =min(velocity_y * power, height/5)
	splash(index, fall_force)


func test_splash():
	_start_splash(width/2, 600)


func _validate_property(property: Dictionary) -> void:
	if preset != "Custom":
		var preset_properties = [
		"color",
		"stiffness",
		"damping",
		"power",
		"spread",
		"pass_waves",
		"wave_speed",
		"wave_frequency",
		"wave_amplitude"]
		if property.name in preset_properties:
			property.usage |= PROPERTY_USAGE_READ_ONLY
			#property.usage &= ~PROPERTY_USAGE_EDITOR

func _apply_water_preset():
	color = Color(0.0, 0.246, 0.77, 1.0)
	
	stiffness = 0.007
	damping = 0.03
	power = 0.03
	spread = 0.003

	pass_waves = true
	wave_speed = 2.0
	wave_frequency = 0.3
	wave_amplitude = 0.05


func _apply_lava_preset():
	color = Color(1.0, 0.15, 0.0, 1.0)
	
	stiffness = 0.005
	damping = 0.03
	power = 0.01
	spread = 0.002

	pass_waves = true
	wave_speed = 0.5
	wave_frequency = 0.2
	wave_amplitude = 0.04
