use "logger"

primitive GallopLogFormatter is LogFormatter
  fun apply(msg: String, loc: SourceLoc): String =>
    msg
