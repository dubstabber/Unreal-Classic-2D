extends Control
## Soldat-style front-end: tabs across the top. Tab content is built by each
## child Control's own script. Multiplayer is present but disabled.

func _ready() -> void:
	Profiles.use_ui_presentation()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var tabs: TabContainer = $Tabs
	tabs.set_tab_title(0, "Instant Action")
	tabs.set_tab_title(1, "Multiplayer")
	tabs.set_tab_title(2, "Options")
	tabs.set_tab_title(3, "Player")
	tabs.set_tab_title(4, "Exit")
	tabs.set_tab_disabled(1, true)  # multiplayer not implemented yet
	tabs.current_tab = 0
