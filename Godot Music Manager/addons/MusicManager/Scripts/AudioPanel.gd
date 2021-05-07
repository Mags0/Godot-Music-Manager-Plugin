tool
extends Control

var musicData
var fileSys
var levels = {}							#Level names [track amount]
#Stage data Array = [1, 5, []]			#Start beat, end beat, tracks
var stages = {}							#Level name [stage name] [stage]
#BPM Array = [[1], [120]]				#Beat, Tempo
var bpmTracks = {}						#Level name [bpm]
#Time signature Array = [[4], [4]]		#top, bottom
var timeSigTracks = {}					#Level name [Time sig]
var allBeatsAndBars = {}				#Level name [[bars] [beats]]
var trackControls = {}					#Level name [[volume] [bus name]
var trackItems = {}						#Level name [track number] {[item res files] [itemPositionsInUnits]}
onready var levelPicker = $Levels
var BPMTSTrack = load("res://addons/MusicManager/Scenes/BPM&TimeSig.tscn")
var track = load("res://addons/MusicManager/Scenes/Track.tscn")
onready var holder = $TrackHolder/Holder
var Line
onready var lines = $TrackHolder/Holder/Lines
var whiteLine = load("res://addons/MusicManager/Images/Solidwhite.png")
var currentlySelectedTrack
var item = load("res://addons/MusicManager/Scenes/Item.tscn")
var playNeedlePos : float
var playing : bool
var curTimeSelInUnits : Array = [0, 1]
var stageHighlight = load("res://addons/MusicManager/Scenes/StagePlaceHolder.tscn")
onready var stageSelecter = $Stage
var beatTrigger : int
var barTrigger : int
var beatIniTrigger : int
var barIniTrigger : int
var currentLevel : String
var currentLevelIndex : int
var deleteButton : bool
signal loop
signal next_beat
signal next_bar
var saving : bool
onready var buffer = $TrackPanel/Buffer
onready var zoom = $Stage/ZoomSlider
#warning-ignore:unused_class_variable
onready var snapToggle = $Snap
onready var addTrackButton = $AddTrack
onready var addStageButton = $MarkStage
var updateTrackCheck : bool

func _ready() -> void:
	var configFile = ConfigFile.new()
	var err = configFile.load("user://MusicDataPath.cfg")
	if err == OK:
		var data = configFile.get_value("Music_Data", "File_Path")
		musicData = load(data)
	else:
		musicData = load("res://addons/MusicManager/SaveData/MusicManagerData.tres")
	load_data()
	Line = TextureRect.new()
	Line.name = "Beat"
	Line.texture = whiteLine
	Line.self_modulate.a = 0.25
	Line.expand = true
	Line.stretch_mode = TextureRect.STRETCH_SCALE_ON_EXPAND
	Line.rect_size = Vector2(1, holder.rect_min_size.y-32)
	pass

func load_data() -> void:
	levelPicker.clear()
	levels.clear()
	stages.clear()
	bpmTracks.clear()
	timeSigTracks.clear()
	allBeatsAndBars.clear()
	trackControls.clear()
	trackItems.clear()
	levels = musicData.levels.duplicate()
	stages = musicData.stages.duplicate()
	bpmTracks = musicData.bpmTracks.duplicate()
	timeSigTracks = musicData.timeSigTracks.duplicate()
	allBeatsAndBars = musicData.allBeatsAndBars.duplicate()
	trackControls = musicData.trackControls.duplicate()
	trackItems = musicData.trackItems.duplicate()
	for level in levels.keys():
		levelPicker.add_item(level)

func _process(delta: float) -> void:
	if playing:
		playNeedlePos += (delta*200)
		if playNeedlePos >= curTimeSelInUnits[1]:
			emit_signal("loop")
			playNeedlePos = curTimeSelInUnits[0]
			beatTrigger = beatIniTrigger
			barTrigger = barIniTrigger
		
		if playNeedlePos >= allBeatsAndBars[currentLevel][1][beatTrigger]:
			emit_signal("next_beat")
			beatTrigger += 1
		
		if playNeedlePos >= allBeatsAndBars[currentLevel][0][barTrigger]:
			emit_signal("next_bar")
			barTrigger += 1
	
	if Input.is_key_pressed(KEY_CONTROL):
		if !saving && Input.is_key_pressed(KEY_S):
			saving = true
			save_music()
	else:
		saving = false
	
	if buffer.visible:
		buffer.rect_rotation += 3
	holder.rect_scale = Vector2.ONE * zoom.value*0.1
	
	addTrackButton.disabled = !levelPicker.is_anything_selected()
	updateTrackCheck = !updateTrackCheck
	if updateTrackCheck:
		var aTrackSelected = true
		for track in holder.get_children():
			if track.name != "Lines" && track.name != "BPM&TimeSig":
				if track.selected:
					aTrackSelected = false
		addStageButton.disabled = aTrackSelected

func save_music():
	musicData.levels = levels.duplicate()
	musicData.stages = stages.duplicate()
	musicData.bpmTracks = bpmTracks.duplicate()
	musicData.timeSigTracks = timeSigTracks.duplicate()
	musicData.allBeatsAndBars = allBeatsAndBars.duplicate()
	musicData.trackControls = trackControls.duplicate()
	musicData.trackItems = trackItems.duplicate()
	print("Music Saved")

func new_line_edit(placeHolder: String) -> LineEdit:
	var namer = LineEdit.new()
	namer.rect_size = Vector2(150, 20)
	namer.rect_position = get_local_mouse_position() - Vector2(50, 10)
	namer.placeholder_text = placeHolder
	add_child(namer)
	namer.grab_focus()
	return namer

func _on_AddLevel_button_up() -> void:
	var namer = new_line_edit("New Level Name")
	while !Input.is_key_pressed(KEY_ENTER) && !Input.is_mouse_button_pressed(BUTTON_LEFT):
		yield(get_tree(),"idle_frame")
	if namer.text != "":
		levelPicker.add_item(namer.text)
		levels[namer.text] = [0, false]
		bpmTracks[namer.text] = [[], []]
		timeSigTracks[namer.text] = [[], []]
		allBeatsAndBars[namer.text] = [[], []]
		stages[namer.text] = {}
		trackControls[namer.text] = [[], []]
		trackItems[namer.text] = {}
	namer.queue_free()
	pass

func _on_AddTrack_button_up() -> void:
	levels[currentLevel][0] += 1
	var newTrack = track.instance()
	holder.add_child(newTrack)
	holder.move_child(lines, holder.get_child_count()-1)
	update_holder_size()
	pass

func _on_MarkStage_button_up() -> void:
	var namer = new_line_edit("Stage Name")
	while !Input.is_key_pressed(KEY_ENTER) && !Input.is_mouse_button_pressed(BUTTON_LEFT):
		yield(get_tree(),"idle_frame")
	if namer.text != "":
		var markStage = [curTimeSelInUnits[0], curTimeSelInUnits[1], []]
		for track in holder.get_children():
			if track.name != "Lines" && track.name != "BPM&TimeSig":
				if track.selected:
					markStage[2].append(track.trackNumber)
		stages[currentLevel][namer.text] = markStage.duplicate()
		var newStageHL = stageHighlight.instance()
		newStageHL.musicMan = self
		newStageHL.text = namer.text
		newStageHL.rect_position.x = curTimeSelInUnits[0]
		var Ysize = markStage[2].size()-1
		newStageHL.get_child(0).rect_size = Vector2(curTimeSelInUnits[1] - curTimeSelInUnits[0] + 1, (markStage[2][Ysize]+1)*60+markStage[2][Ysize]+40)
		get_node("TrackHolder/Holder/BPM&TimeSig").stageHighlights.add_child(newStageHL)
		stageSelecter.add_item(namer.text, stages[currentLevel].keys().find(namer.text)+1)
	namer.queue_free()
	pass

func _on_PlayStop_button_up() -> void:
	if $PlayStop.pressed:
		$PlayStop.text = "Stop"
		play_now()
	else:
		$PlayStop.text = "  > Play   "
		stop_now()
	pass

func play_now(reset:= true):
	if reset:
		playNeedlePos = curTimeSelInUnits[0]
		var findBeat = allBeatsAndBars[currentLevel][1].find(curTimeSelInUnits[0]) + 1
		beatTrigger = findBeat
		beatIniTrigger = findBeat
		while allBeatsAndBars[currentLevel][0].find(allBeatsAndBars[currentLevel][1][findBeat]) == -1:
			findBeat += 1
		findBeat = allBeatsAndBars[currentLevel][0].find(allBeatsAndBars[currentLevel][1][findBeat])
		barTrigger = findBeat
		barIniTrigger = findBeat
	playing = true

func stop_now():
	playing = false
	for track in holder.get_children():
		if track.name != "Lines" && track.name != "BPM&TimeSig":
			for item in track.timeline.get_children():
				item.musicClip.stop()

func draw_time_lines(noVisibleUpdate:= false):
	var when = bpmTracks[currentLevel][0].duplicate()
	var bpm = bpmTracks[currentLevel][1].duplicate()
	var TStop = timeSigTracks[currentLevel][0].duplicate()
	var TSBottom = timeSigTracks[currentLevel][1].duplicate()
	var beats = []
	var bars = []
	if lines.get_child_count() > 0 && !noVisibleUpdate:
		for child in lines.get_children():
			child.queue_free()
	when.append(int(when[when.size() - 1]) + 240)
	var markerPosAddup = 0.0
	var lastBarPosition = -1.0
	for beatMarker in when.size()-1:
		var barLength = int(TStop[beatMarker])
		var tempo = 60/float(bpm[beatMarker])
		var length = int(when[beatMarker+1])-int(when[beatMarker])
		var markPosAdd : float
		var tsBottomAmount : float
		match TSBottom[beatMarker]:
			0:
				tsBottomAmount = 400
			1:
				tsBottomAmount = 200
			2:
				tsBottomAmount = 100
		var beatInBar : int
		for beat in length:
			var nextBeat = (tempo*beat)*tsBottomAmount
			if beatInBar >= barLength:
				beatInBar = 0
			var newLine
			if !noVisibleUpdate:
				newLine = Line.duplicate()
				newLine.rect_position.x = markerPosAddup + nextBeat
				lines.add_child(newLine)
			beats.append(markerPosAddup + nextBeat)
			if beatInBar == 0 && markerPosAddup + nextBeat != lastBarPosition:
				bars.append(markerPosAddup + nextBeat)
				if !noVisibleUpdate:
					newLine.rect_size.x = 2
					var barnum = Label.new()
					barnum.text = str(bars.size())
					newLine.add_child(barnum)
					barnum.rect_position.y = -21
				lastBarPosition = markerPosAddup + nextBeat
			markPosAdd = nextBeat
			beatInBar += 1
		markerPosAddup += markPosAdd
	allBeatsAndBars[currentLevel][0] = bars.duplicate()
	allBeatsAndBars[currentLevel][1] = beats.duplicate()
	update_holder_size()
	pass

func update_holder_size():
	if lines.get_child_count() > 0:
		var trackSpace = levels[currentLevel][0] + 2
		holder.rect_min_size = Vector2(lines.get_child(lines.get_child_count()-1).rect_position.x+300, (60*trackSpace)+trackSpace-50)
		for line in lines.get_children():
			line.rect_size.y = holder.rect_min_size.y-32

func _on_NewSoundFile_file_selected(path: String) -> void:
	var trackIndex = currentlySelectedTrack.trackNumber
	if !trackItems[currentLevel].has(trackIndex):
		trackItems[currentLevel][trackIndex] = [[], []]
	trackItems[currentLevel][trackIndex][0].append(path)
	trackItems[currentLevel][trackIndex][1].append(currentlySelectedTrack.mouseXPosition)
	var newItem = item.instance()
	var soundFile = load(path)
	newItem.get_child(0).stream = soundFile
	newItem.get_child(0).bus = AudioServer.get_bus_name(currentlySelectedTrack.busOpt.get_selected_id())
	newItem.text = path
	newItem.rect_size.x = soundFile.get_length()*200
	fileSys.connect("filesystem_changed", newItem, "file_change")
	currentlySelectedTrack.timeline.add_child(newItem)
	pass # Replace with function body.

func go_to_stage(stage_name: String):
	var bpmandts = get_node("TrackHolder/Holder/BPM&TimeSig")
	bpmandts.moving = 0.5
	bpmandts.measures[0].rect_position.x = stages[currentLevel][stage_name][0]
	bpmandts.measures[1].rect_position.x = stages[currentLevel][stage_name][1]
	bpmandts.highlight()
	for track in holder.get_children():
		if track.name != "Lines" && track.name != "BPM&TimeSig":
			track.selected = false
	for trackInd in stages[currentLevel][stage_name][2]:
		holder.get_child(trackInd+1).selected = true
	pass

func _on_Stage_item_selected(ID: int) -> void:
	if ID != 0:
		go_to_stage(stageSelecter.get_item_text(ID))
		stageSelecter.select(0)
	pass # Replace with function body.

func _on_Levels_item_selected(index: int) -> void:
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		select_level(index)
	elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
		var del = new_delete_button("Level")
		while !Input.is_mouse_button_pressed(BUTTON_LEFT):
			yield(get_tree(),"idle_frame")
		if del.pressed:
			var levelName = levelPicker.get_item_text(index)
			levels.erase(levelName)
			bpmTracks.erase(levelName)
			timeSigTracks.erase(levelName)
			allBeatsAndBars.erase(levelName)
			stages.erase(levelName)
			trackControls.erase(levelName)
			trackItems.erase(levelName)
			levelPicker.remove_item(index)
		if index < currentLevelIndex:
			currentLevelIndex -= 1
		levelPicker.select(currentLevelIndex, true)
		del.queue_free()
		deleteButton = false
	pass # Replace with function body.

func select_level(index: int):
	playing = false
	currentLevel = levelPicker.get_item_text(index)
	currentLevelIndex = index
	$TrackHolder.visible = false
	buffer.visible = true
	#sort out lines
	var existingLevel = true if levels[currentLevel][1] else false
	if existingLevel:
		if lines.get_child_count() > 0:
			for child in lines.get_children():
				child.queue_free()
		for beat in allBeatsAndBars[currentLevel][1]:
			var newLine = Line.duplicate()
			newLine.rect_position.x = beat
			lines.add_child(newLine)
			if allBeatsAndBars[currentLevel][0].find(beat):
				newLine.rect_size.x = 2
	
	#Load Level
	for track in holder.get_children():
		if track != lines:
			track.free()
	yield(get_tree(),"idle_frame")
	var bpmtsTrack = BPMTSTrack.instance()
	holder.add_child(bpmtsTrack)
	if !existingLevel:
		bpmtsTrack.create_new_marker(0, false, true)
	else:
		yield(get_tree(),"idle_frame")
		draw_time_lines(true)
	if existingLevel:
		for i in bpmTracks[currentLevel][0].size():
			var aMarker
			if i == 0:
				aMarker = bpmtsTrack.create_new_marker(0, true, true)
			else:
				aMarker = bpmtsTrack.create_new_marker(allBeatsAndBars[currentLevel][1][bpmTracks[currentLevel][0][i]], true)
			aMarker.controls[0].text = bpmTracks[currentLevel][1][i]
			aMarker.controls[1].text = timeSigTracks[currentLevel][0][i]
			aMarker.controls[2].select(timeSigTracks[currentLevel][1][i])
		bpmtsTrack.index_markers(bpmtsTrack.timeline[0].get_child(0))
		yield(get_tree(),"idle_frame")
		draw_time_lines()
	if stages[currentLevel].keys().size() > 0:
		var allStagesInLevel = stages[currentLevel].keys()
		for stage in allStagesInLevel.size():
			var newStageHL = stageHighlight.instance()
			newStageHL.musicMan = self
			newStageHL.text = allStagesInLevel[stage]
			var startTime = stages[currentLevel][allStagesInLevel[stage]][0]
			var endTime = stages[currentLevel][allStagesInLevel[stage]][1]
			var selTracks = stages[currentLevel][allStagesInLevel[stage]][2].duplicate()
			newStageHL.rect_position.x = startTime
			var Ysize = selTracks.size()-1
			newStageHL.get_child(0).rect_size = Vector2(endTime - startTime + 1, (selTracks[Ysize]+1)*60+selTracks[Ysize]+40)
			bpmtsTrack.stageHighlights.add_child(newStageHL)
	for trackNum in levels[currentLevel][0]:
		var newTrack = track.instance()
		newTrack.isLoaded = true
		holder.add_child(newTrack)
		if trackItems[currentLevel].has(trackNum):
			for itemInd in trackItems[currentLevel][trackNum][0].size():
				var newItem = item.instance()
				var soundFile = load(trackItems[currentLevel][trackNum][0][itemInd])
				newItem.get_child(0).stream = soundFile
				newItem.get_child(0).bus = AudioServer.get_bus_name(newTrack.busOpt.get_selected_id())
				newItem.text = trackItems[currentLevel][trackNum][0][itemInd]
				newItem.rect_size.x = soundFile.get_length()*200
				fileSys.connect("filesystem_changed", newItem, "file_change")
				newTrack.timeline.add_child(newItem)
	holder.move_child(lines, holder.get_child_count()-1)
	yield(get_tree().create_timer(0.5),"timeout")
	update_holder_size()
	levels[currentLevel][1] = true
	
	stageSelecter.clear()
	stageSelecter.add_item("[Go To Stage]", 0)
	for newStageIndex in stages[currentLevel].keys().size():
		stageSelecter.add_item(stages[currentLevel].keys()[newStageIndex], newStageIndex+1)
	
	$TrackHolder.visible = true
	buffer.visible = false
	bpmtsTrack.measures[1].rect_position.x = allBeatsAndBars[currentLevel][0][1]+1
	bpmtsTrack.highlight()
	pass # Replace with function body.

func new_delete_button(buttonText: String):
	if !deleteButton:
		deleteButton = true
		var deleteButton = Button.new()
		deleteButton.rect_position = get_local_mouse_position()
		deleteButton.text = "    X Delete " + buttonText + "    "
		add_child(deleteButton)
		return deleteButton

func _on_OpenMusicData_button_up() -> void:
	$Dialog/OpenMusicData.popup_centered_minsize(Vector2(500, 500))
	pass # Replace with function body.

func _on_OpenMusicData_file_selected(path: String) -> void:
	var file = load(path)
	if file is MusicData:
		playing = false
		musicData = file
		var configFile = ConfigFile.new()
		configFile.set_value("Music_Data", "File_Path", path)
		configFile.save("user://MusicDataPath.cfg")
		$TrackHolder.visible = false
		for track in holder.get_children():
			if track != lines:
				track.queue_free()
		load_data()
	pass # Replace with function body.
