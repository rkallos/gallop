use "logger"
use "net"
use "time"

use "../common"

//actor RequestHandler
class RequestHandler
  new create(conn: TCPConnection, data: Array[U8] iso, logger: Logger[String],
    metrics: MetricsSink)
  =>
    let start: U64 = Time.nanos()
    conn.write("go home, ron\n")
    let finish: U64 = Time.nanos()
    metrics("RequestHandler", finish - start)
