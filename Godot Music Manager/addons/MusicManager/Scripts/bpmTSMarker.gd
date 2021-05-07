tool
extends Control

onready var musicMan = get_node("../../../../..")
var changed : float
export var fixed : bool
onready var theTrack = get_node("../..")
var isLoaded : bool
onready var controls : Array = [$BPM, $TimeSigTop, $TimeSigBottom]
var isDeleting : bool

func _ready() -> void:
	changed = -2.0
	yield(get_tree(),"idle_frame")
	if !isLoaded:
		if fixed:
			musicMan.bpmTracks[musicMan.currentLevel][0].append("0")
			$Marker.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			rect_global_position.x = get_global_mouse_position().x
			musicMan.bpmTracks[musicMan.currentLevel][0].append(str(align_to_beats(true)))
		musicMan.bpmTracks[musicMan.currentLevel][1].append("120")
		musicMan.timeSigTracks[musicMan.currentLevel][0].append("4")
		musicMan.timeSigTracks[musicMan.currentLevel][1].append(1)
		if fixed:
			changed = 0.25

func _on_BPM_text_changed(new_text: String) -> void:
	musicMan.bpmTracks[musicMan.currentLevel][1][index()] = new_text
	changed = 0.25
	pass # Replace with function body.

func _on_TimeSigTop_text_changed(new_text: String) -> void:
	musicMan.timeSigTracks[musicMan.currentLevel][0][index()] = new_text
	changed = 0.25
	pass # Replace with function body.

func _on_TimeSigBottom_item_selected(ID: int) -> void:
	musicMan.timeSigTracks[musicMan.currentLevel][1][index()] = ID
	changed = 0.25
	pass # Replace with function body.

func _process(delta: float) -> void:
	if !fixed && $Marker.is_pressed():
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			rect_global_position.x = get_global_mouse_position().x
			rect_position.x = clamp(rect_position.x, 0, theTrack.rect_size.x-150)
			musicMan.bpmTracks[musicMan.currentLevel][0][index()] = align_to_beats(true)
			changed = 0.25
		elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
			isDeleting = true
			index()
			musicMan.bpmTracks[musicMan.currentLevel][0].remove(musicMan.bpmTracks[musicMan.currentLevel][0].size()-1)
			musicMan.bpmTracks[musicMan.currentLevel][1].remove(musicMan.bpmTracks[musicMan.currentLevel][1].size()-1)
			musicMan.timeSigTracks[musicMan.currentLevel][0].remove(musicMan.timeSigTracks[musicMan.currentLevel][0].size()-1)
			musicMan.timeSigTracks[musicMan.currentLevel][1].remove(musicMan.timeSigTracks[musicMan.currentLevel][1].size()-1)
			musicMan.deleteButton = false
			queue_free()
	
	if changed > 0:
		changed -= delta
	elif changed > -1:
		changed = -2.0
		musicMan.draw_time_lines(isLoaded)
		align_to_beats()
		isLoaded = false

func align_to_beats(findBeat:= false):
	var allBeats = musicMan.allBeatsAndBars[musicMan.currentLevel][1].duplicate()
	if findBeat:
		var distance = rect_position.distance_to(Vector2(allBeats[0], 0))
		var closest = 0
		for i in allBeats.size():
			var dist = rect_position.distance_to(Vector2(allBeats[i], 0))
			if dist < distance:
				distance = dist
				closest = i+1
		return closest
	else:
		rect_position.x = allBeats[int(musicMan.bpmTracks[musicMan.currentLevel][0][index(false)])]
	pass

func index(indexMarkers:= true):
	if indexMarkers:
		theTrack.index_markers(self)
	return theTrack.markerPositions.find(rect_position.x)

func update_index_to_manager():
	var ind = index(false)
	musicMan.bpmTracks[musicMan.currentLevel][0][ind] = align_to_beats(true)
	musicMan.bpmTracks[musicMan.currentLevel][1][ind] = controls[0].text
	musicMan.timeSigTracks[musicMan.currentLevel][0][ind] = controls[1].text
	musicMan.timeSigTracks[musicMan.currentLevel][1][ind] = controls[2].get_selected_id()
	changed = 0.1 + (ind*0.05)
