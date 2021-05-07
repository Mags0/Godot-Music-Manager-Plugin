tool
extends Control

onready var measures : Array = [$TimeMeasures/Measure, $TimeMeasures/Measure2]
var hover : bool
var mouseMotion : float
var realignStart : bool
var realignEnd : bool
var moving : float
var hovering : bool
var bpmts = load("res://addons/MusicManager/Scenes/bpmTSMarker.tscn")
onready var holder = get_node("..")
onready var timeline : Array = [$TimeLine, $TimeMeasure]
onready var musicMan = get_node("../../..")
onready var playMarker = $TimeMeasure/PlayMarker
var markerPositions : Array = []
onready var stageHighlights = $StageHighlights

func _ready() -> void:
	name = "BPM&TimeSig"

func _process(delta: float) -> void:
	if measures[0].pressed:
		moving = 0.2
		measures[0].rect_global_position.x = get_global_mouse_position().x
		measures[0].rect_position.x = clamp(measures[0].rect_position.x, 0, measures[1].rect_position.x)
		highlight()
		realignStart = true
	elif measures[1].pressed:
		moving = 0.2
		measures[1].rect_global_position.x = get_global_mouse_position().x
		measures[1].rect_position.x = clamp(measures[1].rect_position.x, measures[0].rect_position.x, rect_size.x-150)
		highlight()
		realignEnd = true
	elif $TimeMeasure/Highlight.pressed:
		moving = 0.2
		measures[0].rect_global_position.x -= mouseMotion - get_global_mouse_position().x
		measures[1].rect_global_position.x -= mouseMotion - get_global_mouse_position().x
		$TimeMeasure/Highlight.rect_global_position.x -= mouseMotion - get_global_mouse_position().x
		measures[0].rect_position.x = clamp(measures[0].rect_position.x, 0, measures[1].rect_position.x)
		measures[1].rect_position.x = clamp(measures[1].rect_position.x, measures[0].rect_position.x, rect_size.x-150)
		highlight()
		realignStart = true
		realignEnd = true
	mouseMotion = get_global_mouse_position().x
	
	if moving <= 0:
		var musicManBeats = musicMan.allBeatsAndBars[musicMan.currentLevel][1].duplicate()
		if realignStart:
			realignStart = false
			var distance = measures[0].rect_position.distance_to(Vector2(musicManBeats[0], -20))
			var closest = musicManBeats[0]
			for i in musicManBeats:
				var dist = measures[0].rect_position.distance_to(Vector2(i, -20))
				if dist < distance:
					distance = dist
					closest = i
			measures[0].rect_position.x = closest
		if realignEnd:
			realignEnd = false
			var distanceend = measures[1].rect_global_position.distance_to(Vector2(musicManBeats[0], -20))
			var closestend = musicManBeats[0]
			for i in musicManBeats:
				var distend = measures[1].rect_position.distance_to(Vector2(i, -20))
				if distend < distanceend:
					distanceend = distend
					closestend = i
			measures[1].rect_position.x = closestend + 1
		highlight()
	else:
		moving -= delta
	
	timeline[0].rect_size.x = holder.rect_min_size.x-150
	timeline[1].rect_size.x = holder.rect_min_size.x-150
	rect_size.x = holder.rect_min_size.x
	
	if musicMan.playing:
		playMarker.rect_position.x = musicMan.playNeedlePos + 17
	playMarker.visible = musicMan.playing

func highlight():
	$TimeMeasure/Highlight.rect_position.x = measures[0].rect_position.x
	$TimeMeasure/Highlight.rect_size.x = measures[1].rect_position.x - measures[0].rect_position.x
	musicMan.curTimeSelInUnits[0] = measures[0].rect_position.x
	musicMan.curTimeSelInUnits[1] = measures[1].rect_position.x - 1

func _on_TimeLine_mouse_entered() -> void:
	hovering = true
	pass # Replace with function body.

func _on_TimeLine_mouse_exited() -> void:
	hovering = false
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.get_button_index() == BUTTON_LEFT && hovering:
		hovering = false
		create_new_marker(get_local_mouse_position().x-150)
		print("created marker")

func create_new_marker(Xpos: float, loaded:= false, fixedStart:= false):
	var newBPMTS = bpmts.instance()
	if fixedStart:
		newBPMTS.fixed = true
		newBPMTS.rect_position = Vector2(0, 0)
	else:
		newBPMTS.rect_position = Vector2(Xpos, 0)
	newBPMTS.isLoaded = loaded
	timeline[0].add_child(newBPMTS)
	if loaded:
		return newBPMTS

func index_markers(caller):
	var atCaller = false
	for marker in timeline[0].get_children():
		if !marker.isDeleting:
			if marker == caller:
				atCaller = true
			if atCaller:
				marker.update_index_to_manager()
	var positions = []
	for marker in timeline[0].get_children():
		if !marker.isDeleting:
			positions.append(marker.rect_position.x)
	positions.sort()
	markerPositions = positions.duplicate()
