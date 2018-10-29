use "collections"
use "logger"
use "net"
use "time"

use "../common"

class RequestFactoryNotify is TCPConnectionNotify
  let _parent: RequestFactory

  new iso create(parent: RequestFactory) =>
    _parent = parent

  fun ref connected(conn: TCPConnection ref) =>
    _parent.connected()

  fun ref connect_failed(conn: TCPConnection ref) =>
    _parent.connect_failed()

  fun ref sent(conn: TCPConnection ref, data: ByteSeq): ByteSeq =>
    data

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso,
    times: USize): Bool
  =>
    true

  fun ref throttled(conn: TCPConnection ref) =>
    _parent.throttled()

  fun ref unthrottled(conn: TCPConnection ref) =>
    _parent.unthrottled()


actor RequestFactory
  let _conn: TCPConnection
  let _logger: Logger[String]
  let _max_size: USize
  var _paused: Bool = false

  new create(auth: AmbientAuth, logger: Logger[String], host: String,
    port: String, max_size: USize = 4096)
  =>
    _conn = TCPConnection(auth, RequestFactoryNotify(this), host, port)
    _max_size = max_size
    _logger = logger

  be connected() =>
    _logger(Fine) and _logger.log("connected")
    lemme_smash()

  be connect_failed() =>
    _logger(Error) and _logger.log("connection failed")
    _conn.dispose()

  be lemme_smash() =>
    if not _paused then
      _conn.write("lemme smash\n")
      lemme_smash()
    end

  be throttled() =>
    _logger(Fine) and _logger.log("throttled")
    _paused = true

  be unthrottled() =>
    _logger(Fine) and _logger.log("unthrottled")
    _paused = false
