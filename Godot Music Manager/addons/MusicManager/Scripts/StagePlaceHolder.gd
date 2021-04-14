tool
extends Button

var musicMan
var sideStageholders : Array = []
var sideHoldwidth : Array = []

func _ready() -> void:
	for stage in get_node("..").get_children():
		if stage != self && stage.rect_position.x == rect_position.x:
			rect_position.x += stage.rect_size.x - 4
			get_child(0).rect_position.x -= stage.rect_size.x - 4
			sideStageholders.append(stage.get_path())
			sideHoldwidth.append(stage.rect_size.x - 4)
	pass

func _process(delta: float) -> void:
	for stage in sideStageholders.size():
		if get_node_or_null(sideStageholders[stage]) == null:
			rect_position.x -= sideHoldwidth[stage]
			get_child(0).rect_position.x += sideHoldwidth[stage]
			sideStageholders.remove(stage)
			sideHoldwidth.remove(stage)
	pass # Replace with function body.

func _on_StagePlaceHolder_button_down() -> void:
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		var del = musicMan.new_delete_button("Stage")
		while !Input.is_mouse_button_pressed(BUTTON_LEFT):
			yield(get_tree(),"idle_frame")
		if del.pressed:
			del.queue_free()
			musicMan.deleteButton = false
			musicMan.stages[musicMan.currentLevel].erase(text)
			musicMan.stageSelecter.clear()
			musicMan.stageSelecter.add_item("[Select]", 0)
			for newStageIndex in musicMan.stages[musicMan.currentLevel].keys().size():
				musicMan.stageSelecter.add_item(musicMan.stages[musicMan.currentLevel].keys()[newStageIndex], newStageIndex+1)
			queue_free()
		else:
			del.queue_free()
			musicMan.deleteButton = false
	pass # Replace with function body.
