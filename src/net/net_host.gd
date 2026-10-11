class_name NetHost
extends Node
## Co-op host. Runs nothing itself: the Game steps the World. The host admits clients (each
## gets a player id and a Survivor), feeds their commands into the World stamped with their
## own player id, and after every SNAPSHOT_TICKS ticks sends everyone a view snapshot with the
## events that happened since the last one.

signal player_joined(player_id: int)
signal player_left(player_id: int)

var world: World
var peer := ENetMultiplayerPeer.new()
## Bytes of the last snapshot sent (for monitoring).
var last_snapshot_bytes := 0
var _players: Dictionary[int, int] = {}  # peer id -> player id
var _events := SimEvents.new()


func start(target: World, port := NetProtocol.DEFAULT_PORT) -> Error:
	world = target
	var error := peer.create_server(port, NetProtocol.MAX_CLIENTS, NetProtocol.CHANNELS)
	if error != OK:
		return error
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	world.stepped.connect(_on_stepped)
	return OK


func player_count() -> int:
	return _players.size()


func stop() -> void:
	if world and world.stepped.is_connected(_on_stepped):
		world.stepped.disconnect(_on_stepped)
	peer.close()


func _process(_delta: float) -> void:
	poll()


func poll() -> void:
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	peer.poll()
	while peer.get_available_packet_count() > 0:
		var sender := peer.get_packet_peer()
		var message := NetProtocol.decode(peer.get_packet())
		if message.is_empty() or not _players.has(sender) or message[0] != NetProtocol.Type.COMMAND:
			continue
		var command: Variant = message[1]
		if command is Dictionary:
			# Never trust the client's player id: it can only act as itself.
			command["player"] = _players[sender]
			world.submit(command)


func _on_peer_connected(peer_id: int) -> void:
	var player_id := 1
	while world.players.has(player_id):
		player_id += 1
	_players[peer_id] = player_id
	world.add_player(player_id)
	world.survivors.spawn(world, player_id, SurvivorSystem.start_cell(world, player_id))
	_send(peer_id, NetProtocol.Type.WELCOME, {"map": world.map.id, "player": player_id, "tick": world.tick},
		NetProtocol.RELIABLE, MultiplayerPeer.TRANSFER_MODE_RELIABLE)
	if DebugLog.on(&"state"):
		DebugLog.event(&"state", {"net_joined": player_id, "peer": peer_id})
	player_joined.emit(player_id)


func _on_peer_disconnected(peer_id: int) -> void:
	var player_id: int = _players.get(peer_id, -1)
	_players.erase(peer_id)
	if DebugLog.on(&"state"):
		DebugLog.event(&"state", {"net_left": player_id, "peer": peer_id})
	player_left.emit(player_id)


func _on_stepped() -> void:
	var events := world.events
	for i in events.count():
		_events.add(events.kinds[i], events.positions[i], events.defs[i], events.ids[i])
	if world.tick % NetProtocol.SNAPSHOT_TICKS != 0 or _players.is_empty():
		return
	var view := WorldState.capture_view(world)
	view["events"] = {"kinds": _events.kinds, "positions": _events.positions, "defs": _events.defs, "ids": _events.ids}
	var bytes := NetProtocol.encode(NetProtocol.Type.SNAPSHOT, view)
	last_snapshot_bytes = bytes.size()
	_events = SimEvents.new()
	peer.set_target_peer(MultiplayerPeer.TARGET_PEER_BROADCAST)
	peer.transfer_channel = NetProtocol.SNAPSHOTS
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	peer.put_packet(bytes)


func _send(peer_id: int, type: NetProtocol.Type, payload: Variant, channel: int, mode: MultiplayerPeer.TransferMode) -> void:
	peer.set_target_peer(peer_id)
	peer.transfer_channel = channel
	peer.transfer_mode = mode
	peer.put_packet(NetProtocol.encode(type, payload))
