tool
extends Button

var offset : float
onready var musicMan = get_node("../..").musicMan
onready var track = get_node("../..")
onready var musicClip = get_child(0)
var copying : bool
var index : int
var file

func _ready() -> void:
	rect_position.x = musicMan.trackItems[musicMan.currentLevel][track.trackNumber][1][get_position_in_parent()]
	musicMan.connect("loop", self, "music_loop")
	musicMan.connect("next_beat", self, "sync_up")
	file = musicClip.stream
	track.rid_of_label()

func _process(delta: float) -> void:
	if pressed:
		rect_global_position.x = get_global_mouse_position().x - offset
	
	if track.selected:
		if musicMan.playing && !musicClip.is_playing():
			if musicMan.playNeedlePos >= rect_position.x && musicMan.playNeedlePos < rect_position.x+rect_size.x:
				musicClip.play((musicMan.playNeedlePos - rect_position.x) / 200)
			else:
				musicClip.stop()
		elif musicClip.is_playing():
			if musicMan.playNeedlePos <= rect_position.x || musicMan.playNeedlePos > rect_position.x+rect_size.x:
				musicClip.stop()
		elif !musicMan.playing:
			musicClip.stop()
	
	musicClip.volume_db = track.actualVolume
	if has_focus():
		if Input.is_key_pressed(KEY_SHIFT):
			if !copying && Input.is_key_pressed(KEY_D):
				copying = true
				musicMan.currentlySelectedTrack = track
				musicMan._on_NewSoundFile_file_selected(text)
		else:
			copying = false
	
	rect_position.x = clamp(rect_position.x, 0, rect_position.x+100)
	pass

func _on_Item_button_down() -> void:
	offset = get_global_mouse_position().x - rect_global_position.x
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		var del = musicMan.new_delete_button("Item")
		while !Input.is_mouse_button_pressed(BUTTON_LEFT):
			yield(get_tree(),"idle_frame")
		if del.pressed:
			del.queue_free()
			musicMan.deleteButton = false
			delete_item()
		else:
			del.queue_free()
			musicMan.deleteButton = false
	pass # Replace with function body.

func delete_item():
	musicMan.trackItems[musicMan.currentLevel][track.trackNumber][0].remove(get_position_in_parent())
	musicMan.trackItems[musicMan.currentLevel][track.trackNumber][1].remove(get_position_in_parent())
	queue_free()

func _on_Item_pressed() -> void:
	track.selected = true
	pass # Replace with function body.

func music_loop():
	musicClip.stop()

func sync_up():
	var sync_position = (musicMan.playNeedlePos - rect_position.x) / 200
	if sync_position < musicClip.get_playback_position()-0.05 || sync_position > musicClip.get_playback_position()+0.05:
		musicClip.seek(sync_position)

func _on_Item_button_up() -> void:
	if musicMan.snapToggle.pressed:
		var allBeats = musicMan.allBeatsAndBars[musicMan.currentLevel][1].duplicate()
		var distance = rect_position.distance_to(Vector2(allBeats[0], rect_position.y))
		var positioner = Vector2(allBeats[0], rect_position.y)
		for i in allBeats.size():
			var dist = rect_position.distance_to(Vector2(allBeats[i], rect_position.y))
			if dist < distance:
				distance = dist
				positioner = Vector2(allBeats[i], rect_position.y)
		rect_position = positioner
	rect_position.x = clamp(rect_position.x, 0, 999999)
	musicMan.trackItems[musicMan.currentLevel][track.trackNumber][1][get_position_in_parent()] = rect_position.x
	pass # Replace with function body.

func file_change():
	text = file.get_path()
	musicMan.trackItems[musicMan.currentLevel][track.trackNumber][0][get_position_in_parent()] = file.get_path()
	pass
