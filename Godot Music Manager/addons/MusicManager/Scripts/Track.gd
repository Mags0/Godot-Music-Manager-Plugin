tool
extends Control

onready var holder = get_node("..")
onready var musicMan = get_node("../../..")
onready var timeline = $TimeLine
onready var selHighlight = $SelHighlight
var selected : bool
var hovering : bool
var selectedSoundFile
onready var busOpt = $BusOption
var mouseXPosition : float
onready var volume = $Volume
var actualVolume : float
var isLoaded : bool
var trackNumber : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var amount = holder.get_child_count() - 2
	rect_position.y = (60*amount)+amount
	trackNumber = get_position_in_parent()-2
	if isLoaded:
		volume.value = musicMan.trackControls[musicMan.currentLevel][0][trackNumber]
		for busInd in AudioServer.get_bus_count():
			busOpt.add_item(AudioServer.get_bus_name(busInd), busInd)
		var selectedBus = musicMan.trackControls[musicMan.currentLevel][1][trackNumber]
		busOpt.select(selectedBus)
		busOpt.text = AudioServer.get_bus_name(selectedBus)
		yield(get_tree(),"idle_frame")
		for item in timeline.get_children():
			item.musicClip.bus = AudioServer.get_bus_name(selectedBus)
	else:
		for busInd in AudioServer.get_bus_count():
			busOpt.add_item(AudioServer.get_bus_name(busInd), busInd)
		musicMan.trackControls[musicMan.currentLevel][0].append(volume.value)
		musicMan.trackControls[musicMan.currentLevel][1].append(0)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timeline.rect_size.x = holder.rect_min_size.x - 150
	selHighlight.rect_size.x = holder.rect_min_size.x
	selHighlight.visible = selected
	musicMan.trackControls[musicMan.currentLevel][1][trackNumber] = busOpt.get_selected_id()
	pass

func _on_TimeLine_mouse_entered() -> void:
	hovering = true
	pass # Replace with function body.

func _on_TimeLine_mouse_exited() -> void:
	hovering = false
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if hovering:
			if event.get_button_index() == BUTTON_LEFT && event.is_pressed():
				selected = !selected
				if !selected:
					for item in timeline.get_children():
						item.musicClip.stop()
			if event.get_button_index() == BUTTON_RIGHT:
				hovering = false
				musicMan.currentlySelectedTrack = self
				mouseXPosition = get_local_mouse_position().x-150
				musicMan.get_node("Dialog/NewSoundFile").popup_centered_minsize(Vector2(500, 500))
		elif event.get_button_index() == BUTTON_RIGHT && get_local_mouse_position().y > 0 && get_local_mouse_position().y < 60 && get_local_mouse_position().x > 0 && get_local_mouse_position().x < 150:
			if !musicMan.deleteButton:
				var del = musicMan.new_delete_button("Track")
				while !Input.is_mouse_button_pressed(BUTTON_LEFT):
					yield(get_tree(),"idle_frame")
				if del.pressed:
					del.queue_free()
					for item in timeline.get_children():
						item.delete_item()
					var childIndex = trackNumber
					musicMan.trackControls[musicMan.currentLevel][0].remove(childIndex-1)
					musicMan.trackControls[musicMan.currentLevel][1].remove(childIndex-1)
					holder.remove_child(self)
					while childIndex < holder.get_child_count()-2:#minus two for lines
						childIndex += 1
						var currentTrack = holder.get_child(childIndex)
						currentTrack.rect_position.y -= 61
						currentTrack.set_controls_to_music_man()
					musicMan.levels[musicMan.currentLevel][0] -= 1
					musicMan.update_holder_size()
					musicMan.deleteButton = false
					queue_free()
				else:
					del.queue_free()
					musicMan.deleteButton = false

func _on_BusOption_mouse_entered() -> void:
	var currentlySelected = busOpt.selected
	busOpt.clear()
	for busInd in AudioServer.get_bus_count():
		busOpt.add_item(AudioServer.get_bus_name(busInd), busInd)
	busOpt.select(currentlySelected)
	pass # Replace with function body.

func _on_BusOption_item_selected(ID: int) -> void:
	for item in timeline.get_children():
		item.musicClip.bus = AudioServer.get_bus_name(ID)
	pass # Replace with function body.

func rid_of_label():
	if get_node_or_null("Label") != null:
		$Label.queue_free()

func _on_Volume_value_changed(value: float) -> void:
	actualVolume = value * 4 - 20
	musicMan.trackControls[musicMan.currentLevel][0][trackNumber] = value
	pass # Replace with function body.

func set_controls_to_music_man():
	musicMan.trackControls[musicMan.currentLevel][0][trackNumber] = volume.value
	pass
