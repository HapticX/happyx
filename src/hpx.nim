import
  regex,
  cligen,
  happyx,
  strutils,
  terminal,
  browsers,
  locks,
  osproc,
  times,
  os

import illwill except fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue, bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


const
  VERSION = "0.9.1"
  SPA_MAIN_FILE = "main"

var
  thr: Thread[void]
  L: Lock


proc ctrlC {. noconv .} =
  ## Hook for Ctrl+C
  illwillDeinit()
  deinitLock(L)
  quit(QuitSuccess)

illwillInit()
setControlCHook(ctrlC)


proc compileProject(): seq[string] {. discardable .} =
  ## Compiling SPA Project
  var
    idx = 0
    arr = ["/", "|", "\\", "-"]
  styledEcho "Compiling ", fgMagenta, SPA_MAIN_FILE, ".js ", fgWhite, "script ... /"
  # Only errors will shows
  var p = startProcess(
    "nim", getCurrentDir() / "src",
    ["js", "--hints:off", "--warnings:off", "--opt:size", "--d:danger", SPA_MAIN_FILE]
  )
  while p.running:
    if idx < arr.len-1:
      inc idx
    else:
      idx = 0
    eraseLine()
    cursorUp()
    styledEcho "Compiling ", fgMagenta, SPA_MAIN_FILE, ".js ", fgWhite, "script ... ", arr[idx]
    sleep(60)
  eraseLine()
  cursorUp()
  let (lines, i) = p.readLines()
  if lines.len == 0:
    styledEcho fgGreen, "Successfully compiled ", fgMagenta, SPA_MAIN_FILE, ".js                  "
  else:
    styledEcho fgRed, "An error was occurred when compiling ", fgMagenta, SPA_MAIN_FILE, ".js     "
    for line in lines:
      echo line
    return lines


proc godEye() {. thread .} =
  ## Got eye that watch all changes in your project files
  let directory = getCurrentDir()
  var
    lastCheck: seq[tuple[path: string, time: times.Time]] = @[]
    currentCheck: seq[tuple[path: string, time: times.Time]] = @[]
  
  for file in directory.walkDirRec():
    lastCheck.add((path: file, time: file.getFileInfo().lastWriteTime))
  
  while true:
    # Get file write times
    for file in directory.walkDirRec():
      currentCheck.add((path: file, time: file.getFileInfo().lastWriteTime))
    # Check
    if currentCheck.len != lastCheck.len:
      acquire(L)
      styledEcho fgGreen, "Changing found ", fgWhite, " reloading ..."
      release(L)
      compileProject()
      lastCheck = @[]
      for i in currentCheck:
        lastCheck.add(i)
      currentCheck = @[]
    else:
      for idx, val in lastCheck:
        if currentCheck[idx] > val and not val.path.endsWith(fmt"{SPA_MAIN_FILE}.js"):
          acquire(L)
          styledEcho fgGreen, "Changing found in ", fgMagenta, val.path, fgWhite, " reloading ..."
          release(L)
          compileProject()
      lastCheck = @[]
      for i in currentCheck:
        lastCheck.add(i)
      currentCheck = @[]
    sleep(20)


proc mainHelpMessage() =
  styledEcho fgBlue, center("# ---=== HappyX CLI ===--- #", 28)
  styledEcho fgGreen, align("v" & VERSION, 28)
  styledEcho(
    "\nCLI for ", fgGreen, "creating", fgWhite, ", ",
    fgGreen, "serving", fgWhite, " and ", fgGreen, "building",
    fgWhite, " HappyX projects\n"
  )
  styledEcho "Usage:"
  styledEcho fgMagenta, "hpx ", fgBlue, "build|dev|create|help ", fgYellow, "[subcommand-args]"


proc buildCommand(optSize: bool = false): int =
  ## TODO
  styledEcho "Welcome to ", styleBright, fgMagenta, "HappyX ", resetStyle, fgWhite, "builder"
  styledEcho fgGreen, "Try to detect SPA project"
  let lines = compileProject()
  if lines.len > 0:
    styledEcho fgRed, "Failure! Project isn't SPA or error wass occurred."
    return QuitFailure
  if not dirExists("build"):
    createDir("build")
  else:
    removeDir("build")
    createDir("build")
  styledEcho fgYellow, "Copying ..."
  copyFileToDir("src" / fmt"{SPA_MAIN_FILE}.js", "build")
  copyFileToDir("src" / "index.html", "build")
  eraseLine()
  cursorUp()
  styledEcho fgGreen, "Obfuscation ..."
  var
    f = open("build" / fmt"{SPA_MAIN_FILE}.js")
    data = f.readAll()
  f.close()
  data = data.replace(re"(\.?)parent(\s*:?)", "$1prnt$2")
  data = data.replace(re"lastJSError", "ljse")
  data = data.replace(re"prevJSError", "pjse")
  data = data.replace(re"/\*[\s\S]+?\*/\s+", "")
  if optSize:
    data = data.replace(re"Uint32Array", "U32A")
    data = data.replace(re"Int32Array", "I32A")
    data = data.replace(re"Array", "A")
    data = data.replace(re"Number", "N")
    data = data.replace(re"String", "S")
    data = data.replace(re"Math", "M")
    data = data.replace(re"BigInt", "B")
    data = data.replace(
      re"\A",
      "const M=Math;const S=String;const B=BigInt;const A=Array;" &
      "const U32A=Uint32Array;const I32A=Int32Array;const N=Number;"
    )
    data = data.replace(re"true", "1")
    data = data.replace(re"false", "0")
  data = data.replace(re"(if|while|for|else if|do|else|switch)\s+", "$1")
  # Find variables and functions
  var
    counter = 0
    found: seq[string] = @[]
  for i in data.findAndCaptureAll(re"\b\w+_\d+\b"):
    if i notin found:
      found.add(i)
      data = data.replace(i, fmt"a{counter}")
      inc counter
  # Find ConstSet, Temporary, Field, NTI\d+ and NNI\d+
  found = @[]
  counter = 0
  for i in data.findAndCaptureAll(re"(ConstSet|Temporary|Field|N[TN]I)\d+"):
    if i notin found:
      found.add(i)
      data = data.replace(i, fmt"b{counter}")
      inc counter
  # Find functions
  found = @[]
  counter = 0
  for i in data.findAndCaptureAll(re"function [c-z][a-zA-Z0-9_]*"):
    if i notin found:
      found.add(i)
      data = data.replace(i[9..^1], fmt" c{counter}")
      inc counter
  data = data.replace(re"(size|base|node):\S+?,", "")
  data = data.replace(re"filename:\S+?,", "")
  data = data.replace(re"finalizer:\S+?}", "}")
  data = data.replace(re"([;{}\]:,\(\)])\s+", "$1")
  data = data.replace(re"  ", " ")
  data = data.replace(re";;", ";")
  data = data.replace(
    re"\s*([\-\+=<\|\*&>^/%!$\?]{1,3})\s*", "$1"
  )
  data = data.replace(
    re"\[\s*", "["
  )
  f = open("build" / fmt"{SPA_MAIN_FILE}.js", fmWrite)
  f.write(data)
  f.close()
  QuitSuccess


proc createCommand(): int =
  ## Create command that asks user for project name and project type
  var
    projectName: string
    selected: int = 0
  let projectTypes = ["SSG", "SPA"]
  styledEcho "New ", fgBlue, styleBright, "HappyX", fgWhite, " project ..."
  # Get project name
  styledWrite stdout, fgYellow, align("Project name: ", 14)
  projectName = readLine(stdin)
  while projectName.len < 1 or projectName.contains(re"[,!\\/':@~`]"):
    styledEcho fgRed, "Invalid name! It doesn't contains one of these symbols: , ! \\ / ' : @ ~ `"
    styledWrite stdout, fgYellow, align("Project name: ", 14)
    projectName = readLine(stdin)

  styledEcho "Ok, now, choose project type ", fgYellow, "(via arrow keys)"
  var
    choosen = false
    needRefresh = true
  while not choosen:
    if needRefresh:
      needRefresh = false
      for i, val in projectTypes:
        if i == selected:
          styledEcho styleUnderscore, fgGreen, "> ", val
        else:
          styledEcho fgYellow, "  ", val
    case getKey()
    of Key.Up, Key.ShiftH:
      if selected > 0:
        needRefresh = true
        dec selected
    of Key.Down, Key.ShiftP:
      if selected < projectTypes.len-1:
        needRefresh = true
        inc selected
    of Key.Enter:
      choosen = true
      break
    else:
      discard
    if needRefresh:
      for i in projectTypes:
        eraseLine(stdout)
        cursorUp(stdout)
  
  styledEcho "Initializing project ..."
  createDir(projectName)
  createDir(projectName / "src")
  # Create .gitignore
  var f = open(projectName / ".gitignore", fmWrite)
  f.write("# Nimcache\nnimcache/\ncache/\n\n# Garbage\n*.exe\n*.log\n*.lg")
  f.close()
  # Create README.md
  f = open(projectName / "README.md", fmWrite)
  f.write("# " & projectName & "\n\n" & projectTypes[selected] & " project written in Nim with HappyX ❤")
  f.close()

  case selected
  of 0:
    # SSG
    createDir(projectName / "src" / "public")
    stdout.styledWrite fgMagenta, "SSG", fgWhite, " was selected. Want to use templates? ", fgYellow, "[Y/N]: "
    var want = ($stdin.readChar()).toLower()
    if want == "y":
      createDir(projectName / "src" / "templates")
      f = open(projectName / "src" / "templates" / "index.html", fmWrite)
      f.write(
        "<!DOCTYPE html><html>\n  <head>\n    <meta charset=\"utf-8\">\n    <title>{{ title }}" &
        "</title>\n  </head>\n  <body>\n    You at {{ title }} page ✨" &
        "\n  </body>\n</html>"
      )
      f.close()
    # Create main file
    f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
    if want == "y":
      f.write(
        "import happyx\n\ntemplateFolder(\"templates\")\n\n" &
        "proc render(title: string): string =\n  renderTemplate(\"index.html\")\n\n" &
        "serve(\"127.0.0.1\", 5000):\n  get \"/{title:string}\":\n    req.answerHtml render(title)\n"
      )
    else:
      f.write("import happyx\n\nserve(\"127.0.0.1\", 5000):\n  get \"/\":\n    \"Hello, world!\"\n")
    f.close()
  of 1:
    # SPA
    createDir(projectName / "public")
    createDir(projectName / "src" / "components")
    f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
    f.write(
      "import\n  happyx,\n  components/[hello_world]\n\n\n" &
      "appRoutes(\"app\"):\n  \"/\":\n    component HelloWorld\n"
    )
    f.close()
    f = open(projectName / "src" / "index.html", fmWrite)
    f.write(
      "<!DOCTYPE html><html>\n  <head>\n    <meta charset=\"utf-8\">\n    <title>" & projectName &
      "</title>\n  </head>\n  <body>\n    " &
      "<div id=\"app\"></div>\n    <script src=\"" & SPA_MAIN_FILE & ".js\"></script>" &
      "\n  </body>\n</html>"
    )
    f.close()
    f = open(projectName / "src" / "components" / "hello_world.nim", fmWrite)
    f.write("import happyx\n\n\ncomponent HelloWorld:\n  `template`:\n    \"Hello, world!\"\n\n  `script`:\n    echo \"Start coding!\"\n")
    f.close()
  else:
    discard
  styledEcho fgGreen, "Successfully created ", fgMagenta, projectName, fgGreen, " project!"
  QuitSuccess


proc devCommand(host: string = "127.0.0.1", port: int = 5000,
                reload: bool = false): int =
  ## Serve
  compileProject()
  if reload:
    initLock(L)
    createThread(thr, godEye)
  # Start server
  styledEcho "Server launched at ", fgGreen, styleUnderscore, "http://", host, ":", $port, fgWhite
  openDefaultBrowser("http://" & host & ":" & $port & "/#/")
  serve(host, port):
    get "/":
      let
        f = open(getCurrentDir() / "src" / "index.html")
        data = f.readAll()
      f.close()
      req.answerHtml(data)
    
    get "/{file:path}":
      var result = ""
      let path = getCurrentDir() / "src" / file
      if fileExists(path):
        let
          f = open(path)
          data = f.readAll()
        f.close()
        result = data
      req.answer(result)

proc mainCommand(version = false): int =
  if version:
    styledEcho "HappyX ", fgGreen, VERSION
  else:
    mainHelpMessage()
  QuitSuccess


when isMainModule:
  dispatchMultiGen(
    [buildCommand, cmdName = "build"],
    [
      devCommand,
      cmdName = "dev"
    ],
    [createCommand, cmdName = "create"],
    [
      mainCommand,
      short = {"version": 'v'}
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
  of "dev":
    quit(dispatchdev(cmdline = pars[1..^1]))
  of "create":
    quit(dispatchcreate(cmdline = pars[1..^1]))
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
      styledEcho "Usage:\n"
      styledEcho fgMagenta, "hpx build"
      styledEcho "Optional arguments:"
      styledEcho align("opt-size", 8), "|o - Optimize JS file size"
    of "dev":
      styledEcho fgBlue, "HappyX", fgMagenta, " dev ", fgWhite, "command starting dev server for SPA project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "hpx dev\n"
      styledEcho "Optional arguments:"
      styledEcho align("host", 8), "|h - change address (default is 127.0.0.1)"
      styledEcho align("port", 8), "|p - change port (default is 5000)"
      styledEcho align("reload", 8), "|r - enable autoreloading"
    of "create":
      styledEcho fgBlue, "HappyX", fgMagenta, " create ", fgWhite, "command creates a new HappyX project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "hpx create"
    else:
      styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmdHelp
  of "":
    quit(dispatchmainCommand(cmdline = pars[0..^1]))
  else:
    styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmd
    quit(QuitFailure)
