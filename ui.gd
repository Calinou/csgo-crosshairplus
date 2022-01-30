extends Control

const SERVER_PORT = 7355

var gsi_server := GSIServer.new()

onready var health_label := $Health as Label
onready var ammo_clip_label := $AmmoClip as Label


class GSIServer extends "res://httpserver.gd":
	signal health_changed(health)
	signal ammo_clip_changed(ammo_clip)
	
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
		var health: int = json.get("player", {}).get("state", {}).get("health", -1)
		var ammo_clip: int = json.get("player", {}).get("weapons", {}).get("weapon_2", {}).get("ammo_clip", -1)
		emit_signal("health_changed", health)
		emit_signal("ammo_clip_changed", ammo_clip)

		var response := Response.new()
		response.body = "CS:GO CrosshairPlus GSI".to_ascii()
		return response


func _ready() -> void:
	# Required for per-pixel transparency to work.
	get_viewport().transparent_bg = true
	
	var __ = gsi_server.listen(SERVER_PORT)
	__ = gsi_server.connect("health_changed", self, "set_health")
	__ = gsi_server.connect("ammo_clip_changed", self, "set_ammo_clip")
	

func set_health(p_health: int):
	if p_health >= 1:
		health_label.text = str(p_health)
	else:
		# Dead or unknown (-1) health.
		health_label.text = ""


func set_ammo_clip(p_ammo_clip: int):
	if p_ammo_clip >= 0:
		ammo_clip_label.text = str(p_ammo_clip)
	else:
		# Unknown (-1) ammo clip status.
		ammo_clip_label.text = ""
