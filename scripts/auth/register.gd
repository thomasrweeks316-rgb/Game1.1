extends Control

@onready var _username: LineEdit = $Panel/VBox/Username
@onready var _password: LineEdit = $Panel/VBox/Password
@onready var _confirm: LineEdit = $Panel/VBox/Confirm
@onready var _error: Label = $Panel/VBox/Error
@onready var _register_btn: Button = $Panel/VBox/RegisterBtn
@onready var _back_btn: Button = $Panel/VBox/BackBtn


func _ready() -> void:
	UIHelpers.style_panel($Panel)
	UIHelpers.style_line_edit(_username)
	UIHelpers.style_line_edit(_password)
	UIHelpers.style_line_edit(_confirm)
	UIHelpers.style_button(_register_btn)
	UIHelpers.style_button(_back_btn)
	_password.secret = true
	_confirm.secret = true
	_register_btn.pressed.connect(_on_register)
	_back_btn.pressed.connect(_on_back)


func _on_register() -> void:
	if _password.text != _confirm.text:
		_error.text = "Passwords do not match."
		return
	var err := AccountManager.register(_username.text, _password.text)
	if err.is_empty():
		err = AccountManager.login(_username.text, _password.text)
		if err.is_empty():
			get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
			return
	_error.text = err


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
