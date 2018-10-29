use "logger"
use "net"
use "time"

use "../common"

class RequestHandler
  new create(conn: TCPConnection, data: Array[U8] iso, logger: Logger[String],
    metrics: MetricsSink)
  =>
    let start: U64 = Time.nanos()

    var count: USize = String.from_array(consume data).count("\n")

    let reply: String = "go home, ron\n"
    let msg = recover trn String(reply.size() * count) end

    while count > 0 do
      msg.append(reply)
      metrics("RequestHandler", Time.nanos() - start)
      count = count - 1
    end

    conn.write(consume msg)
