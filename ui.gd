extends Control

const SERVER_PORT = 7355
const health_gradient = preload("res://ui/health_gradient.tres")
const ammo_clip_gradient = preload("res://ui/ammo_clip_gradient.tres")

var gsi_server := GSIServer.new()

onready var health_control := $Health as Control
onready var health_label := $Health/Label as Label
onready var health_progress := $Health/ProgressBar as ProgressBar
onready var ammo_clip_primary_control := $AmmoClipPrimary as Control
onready var ammo_clip_primary_label := $AmmoClipPrimary/Label as Label
onready var ammo_clip_primary_progress := $AmmoClipPrimary/ProgressBar as ProgressBar
onready var ammo_clip_secondary_control := $AmmoClipSecondary as Control
onready var ammo_clip_secondary_label := $AmmoClipSecondary/Label as Label
onready var ammo_clip_secondary_progress := $AmmoClipSecondary/ProgressBar as ProgressBar


class GSIServer extends "res://httpserver.gd":
	signal health_changed(health)
	signal ammo_clip_primary_changed(ammo_clip, ammo_clip_max, weapon_active)
	signal ammo_clip_secondary_changed(ammo_clip, ammo_clip_max, weapon_active)

	func _respond(request: Request) -> Response:
		print("response")
#		var body := PoolByteArray()
#		body.append_array(("Method: %s\n" % request.method).to_ascii())
#		body.append_array(("Path: %s\n" % request.request_path).to_ascii())
#		body.append_array(("Query: %s\n" % request.request_query).to_ascii())
#		for header in request.headers:
#			body.append_array((header + "\n").to_ascii())
#		body.append_array("Body: ".to_ascii())
#		body.append_array(request.request_data)

		var json: Dictionary = parse_json(request.request_data.get_string_from_ascii())

		# FIXME: Weapon order is not guaranteed. It depends on the order weapons were picked up.
		# Secondary weapon should be checked by type ("Pistol") instead of slot.
		# Also, if you spawn with the bomb or pick up any grenades, the weapon order will change.
		# and ammo bars will no longer function.
		# (Picking up the bomb after buying a primary weapon will not do this,
		# as the bomb will be last in the weapon order.)
		var health: int = json.get("player", {}).get("state", {}).get("health", -1)
		emit_signal("health_changed", health)

		# FIXME: Weapon state fading doesn't work for the primary weapon, only for the secondary weapon.
		var ammo_clip_primary: int = json.get("player", {}).get("weapons", {}).get("weapon_2", {}).get("ammo_clip", -1)
		var ammo_clip_primary_max: int = json.get("player", {}).get("weapons", {}).get("weapon_2", {}).get("ammo_clip_max", -1)
		var primary_state: String = json.get("player", {}).get("weapons", {}).get("weapon_2", {}).get("state", "")
		emit_signal("ammo_clip_primary_changed", ammo_clip_primary, ammo_clip_primary_max, primary_state == "active")

		var ammo_clip_secondary: int = json.get("player", {}).get("weapons", {}).get("weapon_1", {}).get("ammo_clip", -1)
		var ammo_clip_secondary_max: int = json.get("player", {}).get("weapons", {}).get("weapon_1", {}).get("ammo_clip_max", -1)
		var secondary_state: String = json.get("player", {}).get("weapons", {}).get("weapon_1", {}).get("state", "")
		emit_signal("ammo_clip_secondary_changed", ammo_clip_secondary, ammo_clip_secondary_max, secondary_state == "active")

		var response := Response.new()
		response.body = "CS:GO CrosshairPlus GSI".to_ascii()
		return response


func _ready() -> void:
	# Required for per-pixel transparency to work.
	get_viewport().transparent_bg = true

	# The window spawns centered, which means it's on top of the crosshair.
	# Move window to be slightly below the crosshair.
	OS.window_position.y += 75

	# Comment out the line below to test health/ammo display without having to run CS:GO.
	set_process(false)

	var __ = gsi_server.listen(SERVER_PORT)
	__ = gsi_server.connect("health_changed", self, "set_health")
	__ = gsi_server.connect("ammo_clip_primary_changed", self, "set_ammo_clip_primary")
	__ = gsi_server.connect("ammo_clip_secondary_changed", self, "set_ammo_clip_secondary")


func _process(_delta: float) -> void:
	if Engine.get_idle_frames() % 15 == 0:
		set_health(int(health_label.text) - 1)
		set_ammo_clip_primary(int(ammo_clip_primary_label.text) - 1)
		set_ammo_clip_secondary(int(ammo_clip_secondary_label.text) - 1)


func set_health(p_health: int):
	if p_health >= 1:
		health_label.text = str(p_health)
		health_progress.value = p_health
		health_control.modulate = health_gradient.interpolate(p_health / health_progress.max_value)
	else:
		# Dead or unknown (-1) health.
		health_label.text = ""
		health_progress.value = 0.0


func set_ammo_clip_primary(p_ammo_clip: int, p_ammo_clip_max: int = -1, p_weapon_active: bool = true):
	if p_ammo_clip >= 0:
		ammo_clip_primary_label.text = str(p_ammo_clip)
		ammo_clip_primary_progress.value = p_ammo_clip
		if p_ammo_clip_max >= 1:
			ammo_clip_primary_progress.max_value = p_ammo_clip_max
			ammo_clip_primary_control.modulate = ammo_clip_gradient.interpolate(p_ammo_clip / float(p_ammo_clip_max))
		if not p_weapon_active:
			# Weapon holstered or reloading. Fade out the label and progress bar.
			ammo_clip_secondary_control.modulate.a = 0.6
	else:
		# Unknown (-1) ammo clip status.
		ammo_clip_primary_label.text = ""
		ammo_clip_primary_progress.value = 0.0


func set_ammo_clip_secondary(p_ammo_clip: int, p_ammo_clip_max: int = -1, p_weapon_active: bool = true):
	if p_ammo_clip >= 0:
		ammo_clip_secondary_label.text = str(p_ammo_clip)
		ammo_clip_secondary_progress.value = p_ammo_clip
		if p_ammo_clip_max >= 1:
			ammo_clip_secondary_progress.max_value = p_ammo_clip_max
			ammo_clip_secondary_control.modulate = ammo_clip_gradient.interpolate(p_ammo_clip / float(p_ammo_clip_max))
		if not p_weapon_active:
			# Weapon holstered or reloading. Fade out the label and progress bar.
			ammo_clip_secondary_control.modulate.a = 0.6
	else:
		# Unknown (-1) ammo clip status.
		ammo_clip_secondary_label.text = ""
		ammo_clip_secondary_progress.value = 0.0
