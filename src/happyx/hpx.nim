import
  # thirdparty
  regex,
  cligen,
  # main library
  ../happyx,
  ./core/constants,
  ./cli/[
    utils,
    create_command, build_command,
    dev_command, serve_command,
    html2tag_command, help_command,
    update_command, project_info_command,
    flags_command, translate_csv_command
  ]

import illwill except
  fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue,
  bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle



proc buildCommandAux(optSize: bool = false, no_compile: bool = false): int = buildCommand(optSize, no_compile)
proc mainHelpMessageAux() = mainHelpMessage()
proc html2tagCommandAux(output: string = "", args: seq[string]): int = html2tagCommand(output, args)
proc updateCommandAux(args: seq[string]): int = updateCommand(args)
proc serveCommandAux(host: string = "0.0.0.0", port: int = 80): int = serveCommand(host, port)
proc projectInfoCommandAux(): int = projectInfoCommand()
proc flagsCommandAux(): int = flagsCommand()
proc translateCsvCommandAux(filename: string, output: string = ""): int =
  translateCsvCommand(filename, output)
proc devCommandAux(host: string = "127.0.0.1", port: int = 5000,
                   reload: bool = false): int =
  devCommand(host, port, reload)
proc createCommandAux(name: string = "", kind: string = "", templates: bool = false,
                      pathParams: bool = false, useTailwind: bool = false, language: string = ""): int =
  createCommand(name, kind, templates, pathParams, useTailwind, language)


proc mainCommand(version = false): int =
  ## HappyX main command
  if version:
    styledEcho "HappyX ", fgGreen, HpxVersion
  else:
    mainHelpMessage()
  shutdownCli()
  QuitSuccess


when isMainModule:
  illwillInit(false)
  dispatchMultiGen(
    [buildCommandAux, cmdName = "build"],
    [devCommandAux, cmdName = "dev"],
    [serveCommandAux, cmdName = "serve"],
    [projectInfoCommandAux, cmdName = "info"],
    [createCommandAux, cmdName = "create"],
    [html2tagCommandAux, cmdName = "html2tag"],
    [updateCommandAux, cmdName = "update"],
    [flagsCommandAux, cmdName = "flags"],
    [translateCsvCommandAux, cmdName = "translatecsv"],
    [
      mainCommand,
      short = {"version": 'v'}
    ]
  )
  var pars = commandLineParams()
  let
    subcmd =
      if pars.len > 0 and not pars[0].startsWith("-"):
        pars[0]
      else:
        ""
  if pars.find("no-emoji") != -1:
    pars.delete(pars.find("no-emoji"))
    useEmoji = false
  elif pars.find("-no-emoji") != -1:
    pars.delete(pars.find("-no-emoji"))
    useEmoji = false
  elif pars.find("--no-emoji") != -1:
    pars.delete(pars.find("--no-emoji"))
    useEmoji = false
  utils.init()
  case subcmd
  of "build":
    quit(dispatchbuild(cmdline = pars[1..^1]))
  of "flags":
    quit(dispatchflags(cmdline = pars[1..^1]))
  of "dev":
    quit(dispatchdev(cmdline = pars[1..^1]))
  of "serve":
    quit(dispatchserve(cmdline = pars[1..^1]))
  of "info":
    quit(dispatchinfo(cmdline = pars[1..^1]))
  of "create":
    quit(dispatchcreate(cmdline = pars[1..^1]))
  of "html2tag":
    quit(dispatchhtml2tag(cmdline = pars[1..^1]))
  of "update":
    quit(dispatchupdate(cmdline = pars[1..^1]))
  of "translate-csv":
    quit(dispatchtranslatecsv(cmdline = pars[1..^1]))
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
      mainHelpMessage()
    of "build":
      styledEcho fgBlue, "HappyX", fgMagenta, " build ", fgWhite, " command builds standalone SPA project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx build\n"
      styledEcho "Optional arguments:"
      styledEcho fgBlue, align("opt-size", 10), "|o", fgWhite, " - Optimize JS file size"
      styledEcho fgYellow, "Use ", fgMagenta, "--no-emoji", fgYellow, " flag to disable emoji"
    of "dev":
      styledEcho fgBlue, "HappyX", fgMagenta, " dev ", fgWhite, "command starting dev server for SPA project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx dev\n"
      styledEcho "Optional arguments:"
      styledEcho fgBlue, align("host", 8), "|h", fgWhite, " - change address (default is 127.0.0.1) (ex. --host:127.0.0.1)"
      styledEcho fgBlue, align("port", 8), "|p", fgWhite, " - change port (default is 5000) (ex. --port:5000)"
      styledEcho fgBlue, align("reload", 8), "|r", fgWhite, " - enable autoreloading (ex. --reload)"
      styledEcho fgYellow, "Use ", fgMagenta, "--no-emoji", fgYellow, " flag to disable emoji"
    of "serve":
      styledEcho fgBlue, "HappyX", fgMagenta, " serve ", fgWhite, "command starting product server for SPA project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx dev\n"
      styledEcho "Optional arguments:"
      styledEcho fgBlue, align("host", 6), "|h", fgWhite, " - change address (default is 0.0.0.0) (ex. --host:0.0.0.0)"
      styledEcho fgBlue, align("port", 6), "|p", fgWhite, " - change port (default is 80) (ex. --port:80)"
      styledEcho fgYellow, "Use ", fgMagenta, "--no-emoji", fgYellow, " flag to disable emoji"
    of "create":
      styledEcho fgBlue, "HappyX", fgMagenta, " create ", fgWhite, "command creates a new HappyX project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx create\n"
      styledEcho "Optional arguments:"
      styledEcho fgBlue, align("name", 14), "|n", fgWhite, " - Project name (ex. --name:\"Hello, world!\")"
      styledEcho fgBlue, align("kind", 14), "|k", fgWhite, " - Project type [SPA, SSR] (ex. --kind:SPA)"
      styledEcho fgBlue, align("templates", 14), "|t", fgWhite, " - Enable templates (only for SSR) (ex. --templates)"
      styledEcho fgBlue, align("path-params", 14), "|p", fgWhite, " - Use path params assignment (ex. --path-params)"
      styledEcho fgBlue, align("use-tailwind", 14), "|u", fgWhite, " - Use Tailwind CSS 3 (only for SPA) (ex. --use-tailwind)"
      styledEcho fgYellow, "Use ", fgMagenta, "--no-emoji", fgYellow, " flag to disable emoji"
    of "html2tag":
      styledEcho fgBlue, "HappyX", fgMagenta, " html2tag ", fgWhite, "command converts html code into buildHtml macro"
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx html2tag source.html\n"
      styledEcho "Optional arguments:"
      styledEcho fgBlue, align("output", 8), "|o", fgWhite, " - Output file (ex. --output:source)"
      styledEcho fgYellow, "Use ", fgMagenta, "--no-emoji", fgYellow, " flag to disable emoji"
    of "update":
      styledEcho fgBlue, "HappyX", fgMagenta, " update ", fgWhite, "command updates happyx framework."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx update ", fgBlue, "VERSION"
      styledEcho fgYellow, "Use ", fgMagenta, "--no-emoji", fgYellow, " flag to disable emoji"
    of "info":
      styledEcho fgBlue, "HappyX", fgMagenta, " info ", fgWhite, "command displays project information."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx info"
      styledEcho fgYellow, "Use ", fgMagenta, "--no-emoji", fgYellow, " flag to disable emoji"
    of "flags":
      styledEcho fgBlue, "HappyX", fgMagenta, " flags ", fgWhite, "command displays all HappyX Nim flags."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "  hpx flags"
    else:
      styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmdHelp
    shutdownCli()
    quit(QuitSuccess)
  of "":
    quit(dispatchmainCommand(cmdline = pars[0..^1]))
  else:
    styledEcho fgRed, styleBright, "Unknown subcommand: ", fgWhite, subcmd
    styledEcho fgYellow, "Use ", fgMagenta, "hpx help ", fgYellow, "to get all commands"
    shutdownCli()
    quit(QuitFailure)
