import
  strutils,
  terminal,
  cligen


proc ctrlC {. noconv .} =
  quit(QuitSuccess)

setControlCHook(ctrlC)


proc build(): int =
  styledEcho "Builded!"
  QuitSuccess


proc serve(host: string = "127.0.0.1", port: int = 5000): int =
  styledEcho "Starting serve at ", fgGreen, "http://", host, ":", $port, fgWhite, "!"
  QuitSuccess


proc main(version = false): int =
  if version:
    styledEcho "HappyX ", fgGreen, "0.7.0"
  else:
    styledEcho fgYellow, "[Warning] ", fgWhite, "no arguments"
  QuitSuccess


when isMainModule:
  dispatchMultiGen(
    [build],
    [serve],
    [
      main,
      short={"version": 'v'},
      help={"version": "Shows HappyX version"}
    ]
  )

  let
    pars = commandLineParams()
    subcmd =
      if pars.len > 0 and not pars[0].startsWith("-"):
        pars[0]
      else:
        ""
  case subcmd
  of "build":
    quit(dispatchbuild(cmdline = pars[1..^1]))
  of "serve":
    quit(dispatchserve(cmdline = pars[1..^1]))
  of "help":
    let
      subcmdHelp =
        if pars.len > 1 and not pars[1].startsWith("-"):
          pars[1]
        else:
          ""
      use = "hpx $command $args\n$doc\nOptions:\n$options"
    case subcmdHelp:
    of "":
      styledEcho fgBlue, center("# ---=== HappyX CLI ===--- #", 28)
      styledEcho fgGreen, align("v0.7.0", 28)
      styledEcho(
        "\nCLI for ", fgGreen, "creating", fgWhite, ", ",
        fgGreen, "serving", fgWhite, " and ", fgGreen, "building",
        fgWhite, " HappyX projects\n"
      )
      styledEcho "Usage:"
      styledEcho "hpx ", fgBlue, "build|help ", fgYellow, "[subcommand-args]"
    of "build":
      try:
        discard dispatchbuild(@["--help"], usage=use, noHdr=true)
      except HelpOnly:
        discard
    else:
      styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmdHelp
  of "":
    quit(dispatchmain(cmdline = pars[0..^1]))
  else:
    styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmd
    quit(QuitFailure)
