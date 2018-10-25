use "collections"
use "logger"
use "time"

actor MetricsSink
  """
  A MetricsSink holds on to a map of Histograms that can be written to by other
  actors. It periodically logs the values of these Histograms to a Logger.
  """
  let _map: MapIs[String, Histogram ref] = MapIs[String, Histogram ref]
  let _timers: Timers = Timers()
  let _logger: Logger[String]
  var _dirty: Bool = false

  new create(logger: Logger[String], period: U64) =>
    _logger = logger
    _timers(recover iso
      Timer(MetricsSinkTimerNotify(this), Nanos.from_seconds(period),
        Nanos.from_seconds(period))
      end)

  be apply(key: String, value: U64) =>
    let hist = try _map.insert_if_absent(key, Histogram)?(value) end
    _dirty = true

  be dump_to_log() =>
    let msg = recover String(1024) end

    if not _dirty then return end

    for key in _map.keys() do
      try
        let hist = (_map(key) = Histogram) as Histogram
        msg.append(hist_to_string(key, hist))
      else
        msg.append("--Error reading key " + key + "--")
      end
    end
    _logger(Fine) and _logger.log(consume msg)
    _dirty = false

  fun hist_to_string(k: String, h: Histogram ref): String =>
    let size = h.size()
    let msg = recover String(64) end
    msg.>append("key: ")
      .>append(k)
      .>append(", min: ")
      .>append(h.min().string())
      .>append(", ")

    var n: U64 = 0
    let percentiles: Array[(U64, String)] = [
      ((size.f64() * 0.99).u64(), "p99")
      ((size.f64() * 0.90).u64(), "p90")
      ((size.f64() * 0.50).u64(), "p50")
    ]

    for pair in h.counts().pairs() do
      (let i: USize, let v: U64) = pair
      n = n + v

      try
        var next_percentile = percentiles.pop()?
        while (n > next_percentile._1) do
          msg.>append(next_percentile._2)
            .>append(": ")
            .>append((USize(1) << i).string())
            .>append(", ")
          next_percentile = percentiles.pop()?
        end
        percentiles.push(next_percentile)
      end
    end
    msg.>append("max: ")
      .>append(h.max().string())
      .>append(", samples: ")
      .>append(size.string())
    msg

class MetricsSinkTimerNotify is TimerNotify
  let _parent: MetricsSink

  new iso create(parent: MetricsSink) =>
    _parent = parent

  fun ref apply(timer: Timer, count: U64): Bool =>
    _parent.dump_to_log()
    true
