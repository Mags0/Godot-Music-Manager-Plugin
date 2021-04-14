tool
extends EditorPlugin

var panel = load("res://addons/MusicManager/Scenes/AudioPanel.tscn").instance()

func _enter_tree():
	add_control_to_bottom_panel(panel, "Music")
	panel.rect_min_size.y = get_editor_interface().get_editor_viewport().rect_size.y * 0.35
	add_autoload_singleton("Music", "res://addons/MusicManager/Runtime/MusicRuntime.gd")
	connect("resource_saved", self, "save")
	pass

func _exit_tree():
	remove_control_from_bottom_panel(panel)
	remove_autoload_singleton("Music")
	pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		var size = Vector2(get_editor_interface().get_editor_viewport().rect_size.x - 140, OS.window_size.y - (get_editor_interface().get_editor_viewport().rect_size.y+165))
		panel.get_node("TrackPanel").rect_size = size
		panel.get_node("TrackHolder").rect_size = size
		panel.get_node("Levels").rect_size.y = size.y
		panel.get_node("Stage").rect_position.x = get_editor_interface().get_editor_viewport().rect_size.x - 110
		panel.get_node("Dialog").rect_min_size = Vector2(get_editor_interface().get_editor_viewport().rect_size.x, size.y)

func save(resource):
	panel.save_music()
