use "cli"
use "logger"

use "./common"

actor Main
  new create(env: Env) =>
    let cs =
      try
        CommandSpec.parent("gallop", "A TCP client/server duo", [
          OptionSpec.u64("metrics_freq", "Metrics output period (in seconds)",
            'm', U64(1))
        ], [
          CommandSpec.leaf("server", "Run gallop server", [], [
            ArgSpec.u64("port", "Port number")
          ])?
          CommandSpec.leaf("client", "Run gallop client", [], [
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

    (let logger: Logger[String], let metrics: MetricsSink) =
      start_common(cmd, env)

    match cmd.spec().name()
    | "server" =>
      start_server(cmd, logger, metrics)
    | "client" =>
      start_client(cmd, logger, metrics)
    end

  fun start_common(cmd: Command, env: Env): (Logger[String], MetricsSink) =>
    let logger = StringLogger(Fine, env.out, GallopLogFormatter)

    let metrics_freq: U64 = cmd.option("metrics_freq").u64()
    let metrics_sink = MetricsSink(logger, metrics_freq)

    (logger, metrics_sink)


  fun start_server(cmd: Command, logger: Logger[String],
    metrics: MetricsSink)
  =>
    logger.log("starting server")


  fun start_client(cmd: Command, logger: Logger[String],
    metrics: MetricsSink)
  =>
    logger.log("starting client")
