use "logger"
use "net"

use "../common"

class ServerTCPConnectionNotify is TCPConnectionNotify
  let _auth: AmbientAuth
  let _logger: Logger[String]
  let _metrics: MetricsSink

  new iso create(auth: AmbientAuth, logger: Logger[String],
    metrics: MetricsSink)
  =>
    _auth = auth
    _logger = logger
    _metrics = metrics

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    RequestHandler(consume conn, consume data, _logger, _metrics)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _logger(Error) and _logger.log("Connection failed")
    None
