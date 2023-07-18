import
  # stdlib
  asyncdispatch,
  strutils,
  terminal,
  browsers,
  parsecfg,
  htmlparser,
  xmltree,
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
    ptSSG = "SSG",
    ptSSR = "SSR"
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
  VERSION = "1.9.3"
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
  
  let options: set[ProcessOption] =
    when defined(windows):
      {poStdErrToStdOut}
    else:
      {poStdErrToStdOut, poUsePath}

  case result.projectType:
  of ptSPA:
    result.process = startProcess(
      "nim", getCurrentDir() / result.srcDir,
      [
        "js", "-c", "--hints:off", "--warnings:off",
        "--opt:size", "-d:danger", "-x:off", "-a:off", result.mainFile
      ], nil, options
    )
  of ptSSR, ptSSG:
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
          if val.path.endsWith(fmt"{mainFile}.exe") or val.path.endsWith(mainFile):
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


proc xml2Text(xml: XmlNode): string =
  case xml.kind
  of xnElement:
    result = "t" & xml.tag.capitalizeAscii()
    if xml.attrsLen > 0:
      result &= "("
      var attrs: seq[string] = @[]
      for key, value in xml.attrs:
        let k = if key notin NimKeywords: key else: "`" & key & "`"
        if value == "":
          attrs.add(k)
        else:
          attrs.add(k & " = \"" & value & "\"")
      result &= attrs.join(", ") & ")"
    if xml.len > 0:
      result &= ":"
  of xnText:
    if re"\A\s+\z" notin xml.text:
      result = "\"\"\"" & xml.text.replace(re" +\z", "") & "\"\"\""
  of xnComment:
    result = "#[" & xml.text & "]#"
  else:
    discard


proc xmlTree2Text(data: var string, tree: XmlNode, lvl: int = 2) =
  let text = tree.xml2Text()
  if text.len > 0:
    data &= ' '.repeat(lvl) & tree.xml2Text() & "\n"
  
  if tree.kind == xnElement:
    for child in tree.items:
      data.xmlTree2Text(child, lvl+2)


proc mainHelpMessage() =
  styledEcho fgBlue, center("# ---=== HappyX CLI ===--- #", 28)
  styledEcho fgGreen, align("v" & VERSION, 28)
  styledEcho(
    "\nCLI for ", fgGreen, "creating", fgWhite, ", ",
    fgGreen, "serving", fgWhite, " and ", fgGreen, "building",
    fgWhite, " HappyX projects\n"
  )
  styledEcho "Usage:"
  styledEcho fgMagenta, "hpx ", fgBlue, "build|dev|create|html2tag|help ", fgYellow, "[subcommand-args]"


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
  # Delete comments
  data = data.replace(re"//[^\n]+\s+", "")
  data = data.replace(re"/\*[^\*]+?\*/\s+", "")
  # Small optimize
  data = data.replace(re"(\.?)parent(\s*:?)", "$1p$2")
  data = data.replace(re"\blastJSError\b", "le")
  data = data.replace(re"\bprevJSError\b", "pe")
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
  # Compress expressions
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
  styledEcho fgGreen, "Build completed"
  illwillDeinit()
  QuitSuccess


proc html2tagCommand(output: string = "", args: seq[string]): int =
  var o = output
  
  # Check args
  if args.len != 1:
    if args.len == 0:
      styledEcho fgRed, "Argument required!"
    else:
      styledEcho fgRed, "Only one argument allowed!"
    styledEcho fgRed, "Ex. ", fgMagenta, "hpx html2tag ", fgYellow, "source.html"
  
  # input file
  var filename = args[0]
  
  # Check output
  if o.len == 0:
    o = "source.nim"
  # Check output extension
  if o.split('.').len == 1:
    o &= ".nim"
  # Check input extension
  if filename.split('.').len == 1:
    filename &= ".html"

  var file = open(filename, fmRead)
  let input = file.readAll()
  file.close()

  var
    tree = parseHtml(input)
    outputData = "import happyx\n\n\nvar html = buildHtml:\n"
  xmlTree2Text(outputData, tree, 2)

  outputData = outputData.replace(re"""( +)(tScript.*?:)\s+(\"{3})\s*([\s\S]+?)(\"{3})""", "$1$2 $3\n  $1$4$1$5")

  file = open(o, fmWrite)
  file.write(outputData)
  file.close()


proc createCommand(name: string = "", kind: string = "", templates: bool = false,
                   pathParams: bool = false, useTailwind: bool = false): int =
  ## Create command that asks user for project name and project type
  var
    projectName: string
    selected: int = 0
    imports = @["happyx"]
  let projectTypes = ["SSR", "SSG", "SPA"]
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
  of 0, 1:
    # SSR/SSG
    createDir(projectName / "src" / "public")
    if templates:
      styledEcho fgYellow, "Templates in SSR was enabled. To disable it remove --templates flag."
      createDir(projectName / "src" / "templates")
      f = open(projectName / "src" / "templates" / "index.html", fmWrite)
      f.write(
        "<!DOCTYPE html><html>\n  <head>\n    <meta charset=\"utf-8\">\n    <title>{{ title }}" &
        "</title>\n  </head>\n  <body>\n    You at {{ title }} page ✨" &
        "\n  </body>\n</html>"
      )
      f.close()
    else:
      styledEcho fgYellow, "Templates in SSR was disabled. To enable it add --templates flag."
    # Create main file
    f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
    if templates:
      f.write(
        "# Import HappyX\n" &
        "import\n  " & imports.join(",\n  ") & "\n\n" &
        "# Declare template folder\n" &
        "templateFolder(\"templates\")\n\n" &
        "proc render(title: string): string =\n" &
        "  ## Renders template and returns HTML string\n" &
        "  ## \n" &
        "  ## `title` is template argument\n" &
        "  renderTemplate(\"index.html\")\n\n" &
        "# Serve at http://127.0.0.1:5000\n" &
        "serve(\"127.0.0.1\", 5000):\n" &
        "  # on GET HTTP method at http://127.0.0.1:5000/TEXT\n" &
        "  get \"/{title:string}\":\n" &
        "    req.answerHtml render(title)\n" &
        "  # on any HTTP method at http://127.0.0.1:5000/public/path/to/file.ext\n" &
        "  staticDir \"public\"\n\n"
      )
    else:
      f.write(
        "# Import HappyX\n" &
        "import\n  " & imports.join(",\n  ") & "\n\n" &
        "# Serve at http://127.0.0.1:5000\n" &
        "serve(\"127.0.0.1\", 5000):\n" &
        "  # on GET HTTP method at http://127.0.0.1:5000/\n" &
        "  get \"/\":\n" &
        "    # Return plain text\n" &
        "    \"Hello, world!\"\n" &
        "  # on any HTTP method at http://127.0.0.1:5000/public/path/to/file.ext\n" &
        "  staticDir \"public\"\n\n"
      )
    f.close()
  of 2:
    # SPA
    imports.add("components/[hello_world]")
    createDir(projectName / "src" / "public")
    createDir(projectName / "src" / "components")
    f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
    f.write(
      "# Import HappyX\n" &
      "import\n  " & imports.join(",\n  ") & "\n\n\n" &
      "# Declare application with ID \"app\"\n" &
      "appRoutes(\"app\"):\n" &
      "  \"/\":\n" &
      "    # Component usage\n" &
      "    component HelloWorld\n"
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
    f.write(
      "# Import HappyX\n" &
      "import happyx\n\n\n" &
      "# Declare component\n" &
      "component HelloWorld:\n" &
      "  # Declare HTML template\n" &
      "  `template`:\n" &
      "    tDiv(class = \"someClass\"):\n" &
      "      \"Hello, world!\"\n\n" &
      "  `script`:\n" &
      "    echo \"Start coding!\"\n"
    )
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

  # Launch SSR app
  if project.projectType == ptSSR:
    styledEcho fgRed, "SSR projects not available in the dev mode."
    styledEcho fgMagenta, "Make SSR for dev mode and send Pull Request if you want!"
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
    [html2tagCommand, cmdName = "html2tag"],
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
  of "html2tag":
    quit(dispatchhtml2tag(cmdline = pars[1..^1]))
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
      styledEcho align("host", 8), "|h - change address (default is 127.0.0.1) (ex. --host:127.0.0.1)"
      styledEcho align("port", 8), "|p - change port (default is 5000) (ex. --port:5000)"
      styledEcho align("reload", 8), "|r - enable autoreloading (ex. --reload)"
    of "create":
      styledEcho fgBlue, "HappyX", fgMagenta, " create ", fgWhite, "command creates a new HappyX project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "hpx create\n"
      styledEcho "Optional arguments:"
      styledEcho align("name", 12), "|n - Project name (ex. --name:\"Hello, world!\")"
      styledEcho align("kind", 12), "|k - Project type [SPA, SSR] (ex. --kind:SPA)"
      styledEcho align("templates", 12), "|t - Enable templates (only for SSR) (ex. --templates)"
      styledEcho align("path-params", 12), "|p - Use path params assignment (ex. --path-params)"
      styledEcho align("use-tailwind", 12), "|u - Use Tailwind CSS 3 (only for SPA) (ex. --use-tailwind)"
    of "html2tag":
      styledEcho fgBlue, "HappyX", fgMagenta, " html2tag ", fgWhite, "command converts html code into buildHtml macro"
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "hpx html2tag source.html\n"
      styledEcho align("output", 12), "|o - Output file (ex. --output:source)"
    else:
      styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmdHelp
  of "":
    quit(dispatchmainCommand(cmdline = pars[0..^1]))
  else:
    styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmd
    quit(QuitFailure)
