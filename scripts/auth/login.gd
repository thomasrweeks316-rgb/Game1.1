extends Control

@onready var _username: LineEdit = $Panel/VBox/Username
@onready var _password: LineEdit = $Panel/VBox/Password
@onready var _error: Label = $Panel/VBox/Error
@onready var _login_btn: Button = $Panel/VBox/LoginBtn
@onready var _register_btn: Button = $Panel/VBox/RegisterBtn


func _ready() -> void:
	UIHelpers.style_panel($Panel)
	UIHelpers.style_line_edit(_username)
	UIHelpers.style_line_edit(_password)
	UIHelpers.style_button(_login_btn)
	UIHelpers.style_button(_register_btn)
	_password.secret = true
	_login_btn.pressed.connect(_on_login)
	_register_btn.pressed.connect(_on_register)
	if AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_login() -> void:
	var err := AccountManager.login(_username.text, _password.text)
	if err.is_empty():
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	else:
		_error.text = err


func _on_register() -> void:
	get_tree().change_scene_to_file("res://scenes/auth/register.tscn")
