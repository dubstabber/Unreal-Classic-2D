extends Node
## In-game debug console. Toggle with backtick (`).
## Commands register via DebugConsole.register("name", Callable).
## UI is built in code so this autoload has no .tscn dependency.

var _commands: Dictionary[StringName, Callable] = {}
var _help_text: Dictionary[StringName, String] = {}

var _layer: CanvasLayer
var _panel: Panel
var _vbox: VBoxContainer
var _log: RichTextLabel
var _line: LineEdit
var _open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	register(&"help", _cmd_help, "list commands")
	register(&"echo", _cmd_echo, "print args back")
	register(&"clear", _cmd_clear, "clear console output")
	register(&"quit", func(_a): get_tree().quit(); return null, "quit the game")

func register(name: StringName, fn: Callable, help: String = "") -> void:
	_commands[name] = fn
	_help_text[name] = help

func print_line(s: String) -> void:
	if _log:
		_log.append_text(s + "\n")
	print(s)

func exec(line: String) -> Variant:
	line = line.strip_edges()
	if line.is_empty():
		return null
	var parts: PackedStringArray = line.split(" ", false)
	var name: StringName = StringName(parts[0])
	var args: Array = []
	for i in range(1, parts.size()):
		args.append(parts[i])
	if not _commands.has(name):
		print_line("[color=#ff8888]unknown: %s[/color]" % name)
		return null
	return _commands[name].callv([args])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			_toggle()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	_open = not _open
	_layer.visible = _open
	if _open:
		_line.grab_focus()
		_line.clear()
	else:
		_line.release_focus()

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	add_child(_layer)

	_panel = Panel.new()
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.5
	_panel.offset_left = 8
	_panel.offset_top = 8
	_panel.offset_right = -8
	_panel.offset_bottom = 0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.78)
	sb.border_color = Color(0.55, 0.78, 1, 1)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.anchor_right = 1.0
	_vbox.anchor_bottom = 1.0
	_vbox.offset_left = 6
	_vbox.offset_top = 6
	_vbox.offset_right = -6
	_vbox.offset_bottom = -6
	_panel.add_child(_vbox)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.fit_content = false
	_vbox.add_child(_log)

	_line = LineEdit.new()
	_line.placeholder_text = "type a command, then Enter (` to toggle)"
	_line.text_submitted.connect(_on_submit)
	_vbox.add_child(_line)

func _on_submit(text: String) -> void:
	print_line("[color=#88ddff]> %s[/color]" % text)
	_line.clear()
	var result: Variant = exec(text)
	if result != null:
		print_line(str(result))

func _cmd_help(_args: Array) -> String:
	var out := PackedStringArray()
	var names: Array = _commands.keys()
	names.sort()
	for n in names:
		var help: String = _help_text.get(n, "")
		out.append("  %s — %s" % [String(n), help])
	return "commands:\n" + "\n".join(out)

func _cmd_echo(args: Array) -> String:
	return " ".join(args)

func _cmd_clear(_args: Array) -> Variant:
	_log.clear()
	return null
