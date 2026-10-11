class_name NetClient
extends Node
## Co-op client. On the host's welcome it builds a World for that map (which it never steps)
## and from then on applies the host's view snapshots to it. Commands submitted to that World
## are sent to the host instead of being executed here.

signal welcomed(player_id: int)
signal disconnected

var world: World
var player_id := -1
var peer := ENetMultiplayerPeer.new()
## Seconds since the last snapshot arrived, for interpolation.
var since_snapshot := 0.0
var snapshots := 0


func start(address: String, port := NetProtocol.DEFAULT_PORT) -> Error:
	var error := peer.create_client(address, port, NetProtocol.CHANNELS)
	if error == OK:
		peer.peer_disconnected.connect(func(_id: int) -> void: disconnected.emit())
	return error


func stop() -> void:
	peer.close()


func is_connected_to_host() -> bool:
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Interpolation fraction between the last two snapshots.
func alpha() -> float:
	return clampf(since_snapshot / (NetProtocol.SNAPSHOT_TICKS * SimConstants.TICK_DELTA), 0.0, 1.0)


func _process(delta: float) -> void:
	since_snapshot += delta
	poll()


func poll() -> void:
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	peer.poll()
	var latest: Dictionary = {}
	while peer.get_available_packet_count() > 0:
		var message := NetProtocol.decode(peer.get_packet())
		if message.is_empty():
			continue
		match message[0]:
			NetProtocol.Type.WELCOME:
				_on_welcome(message[1])
			NetProtocol.Type.SNAPSHOT:
				if latest.is_empty() or message[1]["tick"] > latest["tick"]:
					latest = message[1]
	if world and not latest.is_empty() and latest["tick"] >= world.tick:
		WorldState.apply_view(world, latest)
		world.visibility.update(world)
		world.stepped.emit()
		since_snapshot = 0.0
		snapshots += 1
	_send_commands()


func _on_welcome(data: Dictionary) -> void:
	player_id = data["player"]
	world = World.new(MapLayout.load_file("res://data/maps/%s.json" % data["map"]), DefRegistry.load_default(), 0)
	world.tick = data["tick"]
	world.add_player(player_id)  # known right away; snapshots fill in everyone else
	if DebugLog.on(&"state"):
		DebugLog.event(&"state", {"net_welcome": player_id, "map": data["map"]})
	welcomed.emit(player_id)


## Commands the local input submitted to the (never stepped) client World go to the host.
func _send_commands() -> void:
	if world == null:
		return
	var commands := world.take_pending()
	if commands.is_empty():
		return
	peer.set_target_peer(MultiplayerPeer.TARGET_PEER_SERVER)
	peer.transfer_channel = NetProtocol.RELIABLE
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	for command in commands:
		peer.put_packet(NetProtocol.encode(NetProtocol.Type.COMMAND, command))
