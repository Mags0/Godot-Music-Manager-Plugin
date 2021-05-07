extends Node

enum {ON_BEAT, ON_BAR, ON_LOOP, INSTANT}
var musicData
var levels = {}
var stages = {}
var allBeatsAndBars = {}
var trackControls = {}
var trackItems = {}
var currentLevel : String
var currentStage : String
var playNeedlePos : float
var playing : bool
var curTimeSelInUnits : Array = [0, 1]
var beatTrigger : int
var barTrigger : int
var beatIniTrigger : int
var barIniTrigger : int

var curlevelNode

signal on_loop
signal next_beat(beat)
signal next_bar(measure)
signal clip_playing(clip_name, track)

func _init() -> void:
	var configFile = ConfigFile.new()
	var err = configFile.load("user://MusicDataPath.cfg")
	if err == OK:
		var data = configFile.get_value("Music_Data", "File_Path")
		musicData = load(data)
	else:
		musicData = load("res://addons/MusicManager/SaveData/MusicManagerData.tres")
	levels = musicData.levels.duplicate()
	stages = musicData.stages.duplicate()
	allBeatsAndBars = musicData.allBeatsAndBars.duplicate()
	trackControls = musicData.trackControls.duplicate()
	trackItems = musicData.trackItems.duplicate()
	
	for iLevel in trackItems.keys():
		for itrackNum in trackItems[iLevel].keys():
			for iSoundfile in trackItems[iLevel][itrackNum][0].size():
				trackItems[iLevel][itrackNum][0][iSoundfile] = load(trackItems[iLevel][itrackNum][0][iSoundfile])
	
	if levels.keys().size() > 0:
		currentLevel = levels.keys()[0]
	curlevelNode = null
	pass

func _physics_process(delta: float) -> void:
	if playing:
		playNeedlePos += (delta*200)
		if playNeedlePos >= curTimeSelInUnits[1]:
			playNeedlePos = curTimeSelInUnits[0]
			beatTrigger = beatIniTrigger
			barTrigger = barIniTrigger
			emit_signal("on_loop")
		
		if playNeedlePos >= allBeatsAndBars[currentLevel][1][beatTrigger]:
			beatTrigger += 1
			emit_signal("next_beat", beatTrigger - beatIniTrigger)
		
		if playNeedlePos >= allBeatsAndBars[currentLevel][0][barTrigger]:
			barTrigger += 1
			emit_signal("next_bar", barTrigger)
		
		playNeedlePos = clamp(playNeedlePos, curTimeSelInUnits[0], curTimeSelInUnits[1] + delta)
	pass

func set_level_and_play(level: String, stage: String, fade:= 0.5, on_time:= INSTANT):
	if !levels.has(level):
		push_error("'" + level + "' is not a level in the music manager.")
		assert(false)
	if !stages[level].has(stage):
		push_error("'" + stage + "' is not a stage in the level that has just been set.")
		assert(false)
	match on_time:
		INSTANT:
			pass
		ON_BEAT:
			yield(self, "next_beat")
		ON_BAR:
			yield(self, "next_bar")
		ON_LOOP:
			yield(self, "on_loop")
	currentLevel = level
	if stage != "":
		currentStage = stage
	else:
		currentStage = stages[level].keys()[0]
	
	if curlevelNode != null:
		curlevelNode.free()
	curlevelNode = new_level_obj()
	play_stage(stage, INSTANT, fade)
	pass

func set_level(level: String):
	if !levels.has(level):
		push_error("'" + level + "' is not a level in the music manager.")
		assert(false)
	currentLevel = level
	if curlevelNode != null:
		curlevelNode.free()
	curlevelNode = new_level_obj()
	pass

func play_stage(stage: String, on_time:= ON_BAR, fade:= 0.5, overdub:= false):
	if !stages[currentLevel].has(stage):
		push_error("'" + stage + "' is not a stage in the current level, use set_level_and_play().")
		assert(false)
	match on_time:
		INSTANT:
			pass
		ON_BEAT:
			yield(self, "next_beat")
		ON_BAR:
			yield(self, "next_bar")
		ON_LOOP:
			yield(self, "on_loop")
	currentStage = stage
	var tracksToFadeIn = []
	var tracksToFadeOut = []
	for trackNode in stages[currentLevel][stage][2]:
		var curTrackNode = curlevelNode.get_child(trackNode-2)
		if overdub && fade != 0:
			if !curTrackNode.selected:
				tracksToFadeIn.append(curTrackNode)
	for child in curlevelNode.get_children().size():
		var curTrackNode = curlevelNode.get_child(child)
		if overdub && fade != 0:
			if curTrackNode.selected:
				if stages[currentLevel][stage][2].has(child):
					tracksToFadeOut.append(curTrackNode)
		else:
			curTrackNode.selected = false
	for trackNode in stages[currentLevel][stage][2]:
		curlevelNode.get_child(trackNode-2).selected = true
	
	curTimeSelInUnits[0] = stages[currentLevel][stage][0]
	curTimeSelInUnits[1] = stages[currentLevel][stage][1]
	
	if overdub && fade != 0:
		var lerpAmount = 0.0
		while lerpAmount <= 1:
			yield(get_tree(), "idle_frame")
			lerpAmount += get_process_delta_time()/fade
			for iTrack in tracksToFadeIn:
				for iItem in iTrack.get_children():
					iItem.volume_db = lerp(-12, iTrack.actualVolume, lerpAmount)
			for iTrack in tracksToFadeOut:
				for iItem in iTrack.get_children():
					iItem.volume_db = lerp(iTrack.actualVolume, -12, lerpAmount)
		for iTrack in tracksToFadeOut:
			iTrack.selected = false
	elif !overdub:
		playNeedlePos = curTimeSelInUnits[0]
		var findBeat = allBeatsAndBars[currentLevel][1].find(curTimeSelInUnits[0]) + 1
		beatTrigger = findBeat
		beatIniTrigger = findBeat
		while allBeatsAndBars[currentLevel][0].find(allBeatsAndBars[currentLevel][1][findBeat]) == -1:
			findBeat += 1
		findBeat = allBeatsAndBars[currentLevel][0].find(allBeatsAndBars[currentLevel][1][findBeat])
		barTrigger = findBeat
		barIniTrigger = findBeat
		if fade != 0:
			fader(fade)
	
	playing = true
	if !overdub:
		emit_signal("next_beat", 0)
		emit_signal("next_bar", barIniTrigger)
	pass

func stop(fade:= 0.5):
	if fade != 0:
		yield(get_tree().create_timer(0.1), "timeout")
		fader(fade, true)
	else:
		playing = false
	pass

func fader(fade: float, isStopping:= false):
	var fadeOut = Node.new()
	var was_playing = playing
	if was_playing:
		add_child(fadeOut)
		var items = get_tree().get_nodes_in_group("MusicManagerItems")
		for iItem in items:
			if iItem.is_playing():
				var new_sound = AudioStreamPlayer.new()
				new_sound.stream = iItem.stream
				new_sound.bus = iItem.bus
				fadeOut.add_child(new_sound)
				new_sound.play(iItem.get_playback_position())
	if isStopping:
		playing = false
		for childTrack in curlevelNode.get_children():
			childTrack.selected = false
	var lerpAmount = 0.0
	while lerpAmount <= 1:
		yield(get_tree(), "idle_frame")
		var deltaFade = get_process_delta_time()/fade
		if was_playing:
			for sound in fadeOut.get_children():
				sound.volume_db = lerp(sound.volume_db, -60.0, deltaFade)
		lerpAmount += deltaFade
		if !isStopping:
			for childTrack in curlevelNode.get_children():
				for childItem in childTrack.get_children():
					childItem.volume_db = lerp(-60.0, childTrack.actualVolume, lerpAmount)
	fadeOut.queue_free()
	if !isStopping:
		for childTrack in curlevelNode.get_children():
			for childItem in childTrack.get_children():
				childItem.volume_db = childTrack.actualVolume
	pass

func new_level_obj() -> Node:
	var theNode = Node.new()
	add_child(theNode)
	for trackInd in levels[currentLevel][0]:
		var trackNode = track.new()
		theNode.add_child(trackNode)
		var itemVolume = trackControls[currentLevel][0][trackInd] * 4 - 20
		var busName = AudioServer.get_bus_name(trackControls[currentLevel][1][trackInd])
		trackNode.actualVolume = itemVolume
		for itemClip in trackItems[currentLevel][trackInd][1].size():
			var newItem = item.new()
			newItem.volume_db = itemVolume
			newItem.bus = busName
			newItem.timePosition = trackItems[currentLevel][trackInd][1][itemClip]
			newItem.timeEndPosition = trackItems[currentLevel][trackInd][1][itemClip] + trackItems[currentLevel][trackInd][0][itemClip].get_length()*200
			newItem.stream = trackItems[currentLevel][trackInd][0][itemClip] #Is already sound file
			newItem.parentNode = trackNode
			newItem.classNode = self
			trackNode.add_child(newItem)
	return theNode
	pass

class track:
	extends Node
#warning-ignore:unused_class_variable
	var selected : bool
#warning-ignore:unused_class_variable
	var actualVolume : float

class item:
	extends AudioStreamPlayer
	var classNode
	var timePosition : float
	var timeEndPosition : float
	var parentNode
	var shortClip : bool
	
	func _ready() -> void:
		add_to_group("MusicManagerItems")
		if stream.get_length() > 2:
			classNode.connect("next_beat", self, "sync_up")
		else:
			shortClip = true
	
#warning-ignore:unused_argument
	func _process(delta: float) -> void:
		if parentNode.selected:
			if classNode.playing && !is_playing():
				if classNode.playNeedlePos >= timePosition && classNode.playNeedlePos < timeEndPosition:
					if shortClip:
						play()
					else:
						play((classNode.playNeedlePos - timePosition) / 200)
					classNode.emit_signal("clip_playing", stream.get_name(), parentNode.get_position_in_parent())
				else:
					stop()
			elif is_playing():
				if classNode.playNeedlePos <= timePosition || classNode.playNeedlePos > timeEndPosition:
					stop()
			elif !classNode.playing:
				stop()
		elif is_playing():
			stop()
	
	func sync_up(_beat):
		var sync_position = (classNode.playNeedlePos - timePosition) / 200
		if sync_position < get_playback_position()-0.05 || sync_position > get_playback_position()+0.05:
			seek(sync_position)
