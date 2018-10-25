use "logger"
use "net"

use "../common"

class ServerTCPListenNotify is TCPListenNotify
  let _auth: AmbientAuth
  let _logger: Logger[String]
  let _metrics: MetricsSink

  new iso create(auth: AmbientAuth, logger: Logger[String],
    metrics: MetricsSink)
  =>
    _auth = auth
    _logger = logger
    _metrics = metrics

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    try
      (let host: String, let port: String) = listen.local_address().name()?
      let msg: String = "incoming connection from " + host + ":" + port + "."
      _logger(Fine) and _logger.log(msg)
    end
    ServerTCPConnectionNotify(_auth, _logger, _metrics)

  fun ref listening(listen: TCPListener ref) =>
    try
      (_, let port: String) = listen.local_address().name()?
      _logger(Fine) and _logger.log("now listening on port " + port)
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _logger(Error) and _logger.log("error: Unable to listen")
    None
