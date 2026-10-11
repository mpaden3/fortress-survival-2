class_name NetProtocol
## Co-op messages between host and clients: [type, payload] Variants, var_to_bytes encoded,
## snapshots gzip-compressed. Host-authoritative: clients send commands, the host sends state.

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 3
## Channel 0: welcome and commands. Channel 1: snapshots. Both reliable: snapshots are bigger
## than one network frame, and ENet drops a whole unreliable message if any fragment is lost.
## On their own channel they never hold up commands; clients apply only the newest one.
const CHANNELS := 2
const RELIABLE := 0
const SNAPSHOTS := 1
## The host sends a view snapshot every this many ticks.
const SNAPSHOT_TICKS := 2

enum Type { WELCOME, SNAPSHOT, COMMAND }


static func encode(type: Type, payload: Variant) -> PackedByteArray:
	var bytes := var_to_bytes([type, payload])
	if type == Type.SNAPSHOT:
		return var_to_bytes([type, bytes.compress(FileAccess.COMPRESSION_GZIP)])
	return bytes


## [type, payload], or [] if the packet is malformed.
static func decode(packet: PackedByteArray) -> Array:
	var message: Variant = bytes_to_var(packet)
	if not message is Array or (message as Array).size() != 2:
		return []
	if message[0] == Type.SNAPSHOT:
		var inner: Variant = bytes_to_var((message[1] as PackedByteArray).decompress_dynamic(64 * 1024 * 1024,
			FileAccess.COMPRESSION_GZIP))
		return inner if inner is Array else []
	return message
