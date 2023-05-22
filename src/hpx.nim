import
  # stdlib
  asyncdispatch,
  strutils,
  terminal,
  browsers,
  parsecfg,
  locks,
  osproc,
  times,
  os,
  # thirdparty
  regex,
  cligen,
  # main library
  happyx

import illwill except fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue, bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


type
  ProjectType {.pure, size: sizeof(int8).} = enum
    ptSPA = "SPA",
    ptSSG = "SSG"
  ProjectData = object
    process: Process
    mainFile: string
    srcDir: string
    projectType: ProjectType
    error: string
  GodEyeData = object
    needReload: ptr bool
    project: ptr ProjectData


const
  VERSION = "0.24.0"
  SPA_MAIN_FILE = "main"
  CONFIG_FILE = "happyx.cfg"


var
  godEyeThread: Thread[ptr GodEyeData]
  L: Lock


proc ctrlC {. noconv .} =
  ## Hook for Ctrl+C
  illwillDeinit()
  deinitLock(L)
  quit(QuitSuccess)

illwillInit(false)
setControlCHook(ctrlC)


proc compileProject(): ProjectData {. discardable .} =
  ## Compiling Project
  var
    idx = 0
    arr = ["/", "|", "\\", "-"]
  result = ProjectData(
      projectType: ptSPA, srcDir: "src",
      mainFile: SPA_MAIN_FILE,
      process: nil, error: ""
    )

  # Trying to get project config
  if fileExists(getCurrentDir() / CONFIG_FILE):
    let cfg = loadConfig(getCurrentDir() / CONFIG_FILE)
    result.projectType = parseEnum[ProjectType](
      cfg.getSectionValue("Main", "projectType", "SPA").toUpper()
    )
    result.mainFile = cfg.getSectionValue("Main", "mainFile", SPA_MAIN_FILE)
    result.srcDir = cfg.getSectionValue("Main", "srcDir", "src")
  # Only errors will shows
  
  case result.projectType:
  of ptSPA:
    result.process = startProcess(
      "nim", getCurrentDir() / result.srcDir,
      [
        "js", "-c", "--hints:off", "--warnings:off",
        "--opt:size", "--d:danger", "-x:off", "-a:off", result.mainFile
      ]
    )
  of ptSSG:
    return result

  styledEcho "Compiling ", fgMagenta, result.mainFile, fgWhite, " script ... /"

  while result.process.running:
    if idx < arr.len-1:
      inc idx
    else:
      idx = 0
    eraseLine()
    cursorUp()
    styledEcho "Compiling ", fgMagenta, result.mainFile, fgWhite, " script ... ", arr[idx]
    sleep(60)
  eraseLine()
  cursorUp()
  let (lines, i) = result.process.readLines()
  if lines.len == 0:
    styledEcho fgGreen, "Successfully compiled ", fgMagenta, result.mainFile, "                     "
  else:
    styledEcho fgRed, "An error was occurred when compiling ", fgMagenta, result.mainFile, "        "
    for line in lines:
      echo line
      result.error &= line
  if not result.process.isNil():
    result.process.close()


proc godEye(arg: ptr GodEyeData) {. thread, nimcall .} =
  ## Got eye that watch all changes in your project files
  let directory = getCurrentDir()
  var
    lastCheck: seq[tuple[path: string, time: times.Time]] = @[]
    currentCheck: seq[tuple[path: string, time: times.Time]] = @[]
  
  for file in directory.walkDirRec():
    lastCheck.add((path: file, time: file.getFileInfo().lastWriteTime))
  
  let mainFile = arg[].project[].mainFile
  
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
      arg[].needReload[] = true
    else:
      for idx, val in lastCheck:
        if currentCheck[idx] > val and not val.path.endsWith(fmt"{mainFile}.js"):
          if val.path.endsWith(fmt"{mainFile}.exe") or val.path.endsWith(fmt"{mainFile}"):
            continue
          acquire(L)
          styledEcho fgGreen, "Changing found in ", fgMagenta, val.path, fgWhite, " reloading ..."
          release(L)
          compileProject()
          arg[].needReload[] = true
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
  let project = compileProject()
  if project.projectType != ptSPA:
    styledEcho fgRed, "Failure! Project isn't SPA or error wass occurred."
    return QuitFailure
  if not dirExists("build"):
    createDir("build")
    createDir("build" / "public")
  else:
    removeDir("build")
    createDir("build")
    createDir("build" / "public")
  styledEcho fgYellow, "Copying ..."
  copyFileToDir("src" / fmt"{SPA_MAIN_FILE}.js", "build")
  copyFileToDir("src" / "index.html", "build")
  if dirExists("src" / "public"):
    copyDirWithPermissions("src" / "public", "build" / "public")
  if dirExists("public"):
    copyDirWithPermissions("public", "build" / "public")
  eraseLine()
  cursorUp()
  styledEcho fgGreen, "Building ..."
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
  illwillDeinit()
  QuitSuccess


proc createCommand(name: string = "", kind: string = "", templates: bool = false,
                   pathParams: bool = false, useTailwind: bool = false): int =
  ## Create command that asks user for project name and project type
  var
    projectName: string
    selected: int = 0
    imports = @["happyx"]
  let projectTypes = ["SSG", "SPA"]
  styledEcho "New ", fgBlue, styleBright, "HappyX", fgWhite, " project ..."
  if name == "":
    try:
      # Get project name
      styledWrite stdout, fgYellow, align("Project name: ", 14)
      projectName = readLine(stdin)
    except EOFError:
      styledEcho fgRed, "EOF error was occurred!"
      styledEcho fgYellow, "Please, try with flags:"
      styledEcho fgMagenta, "hpx create ", styleBright, "--name=app --kind=SPA"
      return QuitFailure
    while projectName.len < 1 or projectName.contains(re"[,!\\/':@~`]"):
      styledEcho fgRed, "Invalid name! It doesn't contains one of these symbols: , ! \\ / ' : @ ~ `"
      styledWrite stdout, fgYellow, align("Project name: ", 14)
      projectName = readLine(stdin)
  else:
    if projectName.contains(re"[,!\\/':@~`]"):
      styledEcho fgRed, "Invalid name! It doesn't contains one of these symbols: , ! \\ / ' : @ ~ `"
      return QuitFailure
    projectName = name

  if kind == "":
    styledEcho "Choose project type ", fgYellow, "(via arrow keys)"
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
  else:
    selected = projectTypes.find(kind.toUpper())
    if selected < 0:
      styledEcho fgRed, "Invalid project type! it should be one of these [", projectTypes.join(", "), "]"
      return QuitFailure
  
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

  # Write config
  f = open(projectName / CONFIG_FILE, fmWrite)
  f.write(
    "# HappyX project configuration.\n\n" &
    "[Main]\n" &
    "projectName = " & projectName & "\n" &
    "projectType = " & projectTypes[selected] & "\n" &
    "mainFile = main  # main script filename (without extension) that should be launched with hpx dev command\n" &
    "srcDir = src  # source directory\n"
  )
  f.close()

  if pathParams:
    imports.add("path_params")
    f = open(projectName / "src" / "path_params.nim", fmWrite)
    f.write("import happyx\n\n\npathParams:\n  id int\n")
    f.close()
  
  case selected
  of 0:
    # SSG
    createDir(projectName / "src" / "public")
    if templates:
      styledEcho fgYellow, "Templates in SSG was enabled. To disable it remove --templates flag."
      createDir(projectName / "src" / "templates")
      f = open(projectName / "src" / "templates" / "index.html", fmWrite)
      f.write(
        "<!DOCTYPE html><html>\n  <head>\n    <meta charset=\"utf-8\">\n    <title>{{ title }}" &
        "</title>\n  </head>\n  <body>\n    You at {{ title }} page ✨" &
        "\n  </body>\n</html>"
      )
      f.close()
    else:
      styledEcho fgYellow, "Templates in SSG was disabled. To enable it add --templates flag."
    # Create main file
    f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
    if templates:
      f.write(
        "import\n  " & imports.join(",\n  ") & "\n\ntemplateFolder(\"templates\")\n\n" &
        "proc render(title: string): string =\n  renderTemplate(\"index.html\")\n\n" &
        "serve(\"127.0.0.1\", 5000):\n  get \"/{title:string}\":\n    req.answerHtml render(title)\n"
      )
    else:
      f.write(
        "import\n  " & imports.join(",\n  ") &
        "\n\nserve(\"127.0.0.1\", 5000):\n  get \"/\":\n    \"Hello, world!\"\n"
      )
    f.close()
  of 1:
    # SPA
    imports.add("components/[hello_world]")
    createDir(projectName / "src" / "public")
    createDir(projectName / "src" / "components")
    f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
    f.write(
      "import\n  " & imports.join(",\n  ") & "\n\n\n" &
      "appRoutes(\"app\"):\n  \"/\":\n    component HelloWorld\n"
    )
    f.close()
    f = open(projectName / "src" / "index.html", fmWrite)
    var additionalHead = ""
    if useTailwind:
      additionalHead &= "<script src=\"https://cdn.tailwindcss.com\"></script>\n  "
    f.write(
      "<!DOCTYPE html>\n<html>\n  <head>\n    <meta charset=\"utf-8\">\n    <title>" & projectName &
      "</title>\n  " & additionalHead & "</head>\n  <body>\n    " &
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
  illwillDeinit()
  QuitSuccess


proc devCommand(host: string = "127.0.0.1", port: int = 5000,
                reload: bool = false): int =
  ## Serve
  var
    project = compileProject()
    needReload = false
    godEyeData = GodEyeData(
      project: addr project,
      needReload: addr needReload,
    )
    idx = 0
    arr = ["/", "|", "\\", "-"]
  
  if project.error.len > 0:
    return QuitFailure

  if reload:
    initLock(L)
    createThread(godEyeThread, godEye, addr godEyeData)

  # Launch SSG app
  if project.projectType == ptSSG:
    styledEcho fgRed, "SSG projects not available in the dev mode."
    styledEcho fgMagenta, "Make SSG for dev mode and send Pull Request if you want!"
    illwillDeinit()
    deinitLock(L)
    return QuitSuccess

  # Start server for SPA
  styledEcho "Server launched at ", fgGreen, styleUnderscore, "http://", host, ":", $port, fgWhite
  openDefaultBrowser("http://" & host & ":" & $port & "/#/")

  serve(host, port):
    get "/":
      let f = open(getCurrentDir() / "src" / "index.html")
      var data = f.readAll()
      f.close()
      data = data.replace(
        "</body>",
        "<script>" &
        fmt"let socket = new WebSocket('ws://{host}:{port}/hcr');" &
        "\nsocket.onmessage = (event) => {\n" &
        "  if(event.data === 'true'){\n    window.location.reload();\n  }\n" &
        "};\n\n" &
        "function intervalSending(){\n  socket.send('reload')\n}\n\n" &
        "setInterval(intervalSending, 100);\n" &
        "</script></body>"
      )
      req.answerHtml(data)
    
    ws "/hcr":
      if wsData == "reload":
        if needReload:
          needReload = false
          await wsClient.send("true")
        else:
          await wsClient.send("false")
    
    get "/{file:path}":
      var result = ""
      let path = getCurrentDir() / "src" / file.replace('\\', '/').replace('/', DirSep)
      echo "File: ", file
      echo "Path: ", path
      if fileExists(path):
        await req.answerFile(path)
  deinitLock(L)
  illwillDeinit()

proc mainCommand(version = false): int =
  if version:
    styledEcho "HappyX ", fgGreen, VERSION
  else:
    mainHelpMessage()
  illwillDeinit()
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
      styledEcho fgMagenta, "hpx build\n"
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
      styledEcho fgMagenta, "hpx create\n"
      styledEcho "Optional arguments:"
      styledEcho align("name", 12), "|n - Project name"
      styledEcho align("kind", 12), "|k - Project type [SPA, SSG]"
      styledEcho align("templates", 12), "|t - Enable templates (only for SSG)"
      styledEcho align("path-params", 12), "|p - Use path params assignment"
      styledEcho align("use-tailwind", 12), "|u - Use Tailwind CSS 3 (only for SPA)"
    else:
      styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmdHelp
  of "":
    quit(dispatchmainCommand(cmdline = pars[0..^1]))
  else:
    styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmd
    quit(QuitFailure)
