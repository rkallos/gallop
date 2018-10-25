use "cli"
use "logger"
use "net"

use "../common"
use "../server"

actor Main
  new create(env: Env) =>
    let global_opts: Array[OptionSpec] = [
      OptionSpec.u64("metrics_freq", "Metrics output period (in seconds)"
        where short' = 'm', default' = 1)
    ]

    let cs =
      try
        CommandSpec.parent("gallop", "A TCP client/server duo", [], [
          CommandSpec.leaf("server", "Run gallop server", global_opts, [
            ArgSpec.u64("port", "Port number")
          ])?
          CommandSpec.leaf("client", "Run gallop client", global_opts, [
            ArgSpec.string("host", "Hostname or IP")
            ArgSpec.u64("port", "Port number")
          ])?
        ])? .> add_help()?
      else
        env.exitcode(-1)
        return
      end

    let cmd =
      match CommandParser(cs).parse(env.args, env.vars)
      | let c: Command => c
      | let ch: CommandHelp =>
        ch.print_help(env.out)
        env.exitcode(0)
        return
      | let se: SyntaxError =>
        env.out.print(se.string())
        env.exitcode(1)
        return
      end

    env.out.print(cmd.string())

    (let logger: Logger[String], let metrics: MetricsSink) =
      start_common(cmd, env)

    let auth: AmbientAuth =
      try
        env.root as AmbientAuth
      else
        env.exitcode(1)
       return
      end

    match cmd.spec().name()
    | "server" =>
      start_server(auth, cmd, logger, metrics)
    | "client" =>
      start_client(auth, cmd, logger, metrics)
    end

  fun start_common(cmd: Command, env: Env): (Logger[String], MetricsSink) =>
    let logger = StringLogger(Fine, env.out, GallopLogFormatter)

    let metrics_freq: U64 = cmd.option("metrics_freq").u64()
    logger.log("starting metrics collection with freq=" + metrics_freq.string())

    let metrics_sink = MetricsSink(logger, metrics_freq)

    (logger, metrics_sink)


  fun start_server(auth: AmbientAuth, cmd: Command, logger: Logger[String],
    metrics: MetricsSink)
  =>
    let port: String = cmd.arg("port").u64().string()

    logger.log("starting server on port " + port)

    TCPListener(auth, ServerTCPListenNotify(auth, logger, metrics), "", port)


  fun start_client(auth: AmbientAuth, cmd: Command, logger: Logger[String],
    metrics: MetricsSink)
  =>
    logger.log("starting client")
