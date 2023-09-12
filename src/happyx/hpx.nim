import
  # stdlib
  std/asyncdispatch,
  std/strutils,
  std/terminal,
  std/browsers,
  std/parsecfg,
  std/htmlparser,
  std/exitprocs,
  std/sequtils,
  std/xmltree,
  std/locks,
  std/osproc,
  std/times,
  std/math,
  std/algorithm,
  std/os,
  # thirdparty
  regex,
  cligen,
  # main library
  ../happyx,
  ./core/constants

import illwill except
  fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue,
  bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


type
  ProjectType {.pure, size: sizeof(int8).} = enum
    ptSPA = "SPA",
    ptSSG = "SSG",
    ptSSR = "SSR",
    ptSPAHpx = "HPX"
  ProgrammingLanguage {.pure, size: sizeof(int8).} = enum
    plNim = "nim",
    plPython = "python"
  ProjectData = object
    process: Process
    mainFile: string  ## Main file without extension
    srcDir: string  ## Source directory
    projectType: ProjectType  ## Project type (SPA/SSR/SSG)
    error: string
    assetsDir: string  ## Assets directory
    buildDir: string  ## Build directory
    language: ProgrammingLanguage
  GodEyeData = object
    needReload: ptr bool
    project: ptr ProjectData
  
  Progress = ref object
    state: string


const
  SPA_MAIN_FILE = "main"
  CONFIG_FILE = "happyx.cfg"
  PROGRESS_STATES = ["|", "/", "-", "\\"]
  PROCESS_OPTIONS: set[ProcessOption] =
    when defined(windows):
      {poStdErrToStdOut}
    else:
      {poStdErrToStdOut, poUsePath}


var
  godEyeThread: Thread[ptr GodEyeData]
  L: Lock
  deinitialized = false


proc shutdownCli =
  if deinitialized:
    return
  deinitialized = true
  illwillDeinit()
  deinitLock(L)


proc ctrlC {. noconv .} =
  ## Hook for Ctrl+C
  shutdownCli()
  quit(QuitSuccess)

addExitProc(ctrlC)


proc initProgress: Progress = Progress(state: "|")

proc nextState(self: Progress): string =
  var idx = PROGRESS_STATES.find(self.state)
  if idx < PROGRESS_STATES.len - 1:
    inc idx
  else:
    idx = 0
  self.state = PROGRESS_STATES[idx]
  self.state


proc compileProject(): ProjectData {. discardable .} =
  ## Compiling Project
  result = ProjectData(
      projectType: ptSPA, srcDir: "src",
      mainFile: SPA_MAIN_FILE,
      process: nil, error: "",
      assetsDir: "public",
      buildDir: "build"
    )

  # Trying to get project config
  if fileExists(getCurrentDir() / CONFIG_FILE):
    let cfg = loadConfig(getCurrentDir() / CONFIG_FILE)
    result.projectType = parseEnum[ProjectType](
      cfg.getSectionValue("Main", "projectType", "SPA").toUpper()
    )
    result.language = parseEnum[ProgrammingLanguage](
      cfg.getSectionValue("Main", "language", "python").toLower()
    )
    result.mainFile = cfg.getSectionValue("Main", "mainFile", SPA_MAIN_FILE)
    result.srcDir = cfg.getSectionValue("Main", "srcDir", "src")
    result.assetsDir = cfg.getSectionValue("Main", "assetsDir", "public")
    result.buildDir = cfg.getSectionValue("Main", "buildDir", "build")
  # Only errors will shows

  case result.projectType:
  of ptSPA:
    result.process = startProcess(
      "nim", getCurrentDir() / result.srcDir,
      [
        "js", "-c", "--hints:off", "--warnings:off",
        "--opt:size", "-d:danger", "-x:off", "-a:off", "--panics:off", "--lineDir:off", result.mainFile
      ], nil, PROCESS_OPTIONS
    )
  of ptSPAHpx:
    let mainFile = getCurrentDir() / result.srcDir / result.mainFile & ".hpx"
    var componentNames: seq[string] = collect:
      for file in walkDirRec(getCurrentDir() / result.srcDir):
        if file.endsWith(".hpx"):
          file.replace(getCurrentDir() / result.srcDir / "", "")
    # Sort component dependencies
    var usages: seq[(string, string, int)] = @[]
    for currentComponent in componentNames:  # take one component
      var
        usage = 0
        currentComponentName = currentComponent.rsplit('.', 1)[0].rsplit({DirSep, AltSep}, 1)[1]
      for otherComponent in componentNames:  # find it in other components
        if otherComponent != currentComponent:
          var
            x = open(getCurrentDir() / result.srcDir / otherComponent)
            data = x.readAll()
          x.close()
          if re2(r"^\s*<\s*template\s*>[\s\S]+?<\s*" & currentComponentName) in data:
            inc usage
      usages.add((currentComponent, currentComponentName, usage))
    proc sortComp(x, y: (string, string, int)): int {.closure.} =
      cmp(x[2], y[2])
    usages.sort(sortComp, SortOrder.Descending)

    # Load router.json
    var
      routerFile = open(result.srcDir / "router.json")
      routerData = parseJson(routerFile.readAll())
    routerFile.close()

    # Write temporary nim file and compile it into JS
    var f = open(result.srcDir / result.mainFile & ".nim", fmWrite)
    f.write("import happyx\n\n")
    for (path, name, lvl) in usages:
      f.write(fmt"""importComponent "{path.replace("\\", "\\\\")}" as {name}""" & "\n")
    f.write("\nappRoutes \"app\":\n")
    for key, val in routerData.pairs():
      f.write(fmt"""  "{key}":""")
      var
        compName: string = ""
        args = newJObject()
      if val.kind == JString:
        compName = val.getStr
      elif val.kind == JObject:
        if not val.hasKey("component"):
          raise newException(ValueError, fmt"route `{key}` routes should have `component`")
        compName = val["component"].getStr
        args = val["args"]
      if compName.endsWith(".hpx"):
        compName = compName[0..^4]
      f.write("\n")
      f.write(fmt"    component {compName}(")
      for key, arg in args.pairs():
        case arg.kind
        of JString:
          f.write(fmt"{key}={arg.getStr},")
        of JFloat, JBool, JInt:
          f.write(fmt"{key}={arg},")
        of JObject:
          # detect keys is exists
          if not arg.hasKey("name"):
            raise newException(ValueError, fmt"route `{key}` component `{compName}` argument should have `name`")
          if not arg.hasKey("type"):
            raise newException(ValueError, fmt"route `{key}` component `{compName}` argument should have `type`")
          # type validation
          if arg["name"].kind != JString:
            raise newException(ValueError, fmt"route `{key}` component `{compName}` argument `name` should be string")
          if arg["type"].kind != JString:
            raise newException(ValueError, fmt"route `{key}` component `{compName}` argument `type` should be string")
          case arg["type"].getStr.toLower()
          of "pathparam":
            f.write(fmt"""{key}={arg["name"].getStr},""")
          of "query":
            f.write(fmt"""{key}=query~{arg["name"].getStr},""")
          of "queryarr", "queryarray":
            f.write(fmt"""{key}=queryArr~{arg["name"].getStr},""")
        else:
          raise newException(ValueError, fmt"Incorrect router.json structure at `{key}`")
      f.write(")\n\n")
    f.close()
    result.process = startProcess(
      "nim", getCurrentDir() / result.srcDir,
      [
        "js", "-c", "--hints:off", "--warnings:off",
        "--opt:size", "-d:danger", "-x:off", "-a:off", "--panics:off", "--lineDir:off", result.mainFile
      ], nil, PROCESS_OPTIONS
    )
  of ptSSR, ptSSG:
    return result

  styledEcho "Compiling ", fgMagenta, result.mainFile, fgWhite, " script ... /"
  var progress = initProgress()

  while result.process.running:
    eraseLine()
    cursorUp()
    styledEcho "Compiling ", fgMagenta, result.mainFile, fgWhite, " script ... ", progress.nextState
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
  # if result.projectType == ptSPAHpx:
  #   removeFile(result.srcDir / result.mainFile & ".nim")


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
    if re2"\A\s+\z" notin xml.text:
      result = "\"\"\"" & xml.text.replace(re2" +\z", "") & "\"\"\""
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


proc updateHappyx(version: string) =
  var
    process = startProcess(
      "nimble", getCurrentDir(), ["install", "happyx@" & version, "-y"], nil, PROCESS_OPTIONS
    )
    progress = initProgress()
  styledEcho fgYellow, fmt"Updating HappyX ..."
  sleep(100)
  
  for line in process.lines:
    echo line

  if not process.isNil():
    process.close()
  
  sleep(1000)
  styledEcho fgMagenta, "✨ HappyX ", fgGreen, "successfully updated to ", fgMagenta, version


# ---=== Commands ===--- #


proc mainHelpMessage() =
  ## Shows the general help message that describes
  let subcommands = [
    "build", "dev", "serve", "create", "html2tag", "update", "help"
  ]
  styledEcho fgBlue, center("# ---=== 🔥 HappyX CLI 🔥 ===--- #", 28)
  styledEcho fgGreen, align("v" & HpxVersion, 28)
  styledEcho(
    "\nCLI for ", fgGreen, "creating", fgWhite, ", ",
    fgGreen, "serving", fgWhite, " and ", fgGreen, "building",
    fgWhite, " HappyX projects\n"
  )
  styledEcho "Usage:"
  styledEcho fgMagenta, " hpx ", fgBlue, subcommands.join("|"), fgYellow, " [subcommand-args]"


proc updateCommand(args: seq[string]): int =
  var version = "head"
  if args.len > 1:
    styledEcho fgRed, "Only one argument possible for `update` command!"
  else:
    version = args[0]
  
  var v = version.toLower().strip(chars = {'v', '#'})
  case v
  of "head", "latest", "main", "master":
    updateHappyx("#head")
  else:
    if re2"\A(\d+\.\d+\.\d+)\z" in v:
      updateHappyx(v)
    else:
      shutdownCli()
      return QuitFailure
  shutdownCli()
  QuitSuccess


proc buildCommand(optSize: bool = false): int =
  ## Builds Single page application project into one HTML and JS files
  styledEcho "🔥 Welcome to ", styleBright, fgMagenta, "HappyX ", resetStyle, fgWhite, "builder"
  let
    project = compileProject()
    assetsDir = project.assetsDir.replace("\\", "/").replace('/', DirSep)
  if project.projectType != ptSPA:
    styledEcho fgRed, "Failure! Project isn't SPA or error wass occurred."
    return QuitFailure
  if not dirExists(project.buildDir):
    # Create directory if not exists
    createDir(project.buildDir)
    createDir(project.buildDir / assetsDir)
  else:
    # Recreate directory
    removeDir(project.buildDir)
    createDir(project.buildDir)
    createDir(project.buildDir / assetsDir)
  # Start copying
  styledEcho fgYellow, "Copying ..."
  copyFileToDir(project.srcDir / fmt"{SPA_MAIN_FILE}.js",project.buildDir)
  copyFileToDir(project.srcDir / "index.html", project.buildDir)
  if dirExists(project.srcDir / assetsDir):
    copyDirWithPermissions(project.srcDir / assetsDir, project.buildDir / assetsDir)
  eraseLine()
  cursorUp()
  # Start building
  styledEcho fgGreen, "Building ..."
  var
    f = open(project.buildDir / fmt"{SPA_MAIN_FILE}.js")
    data = f.readAll()
  f.close()
  # Delete comments
  data = data.replace(re2"(?<!https?:)//[^\n]+\s+", "")
  data = data.replace(re2"/\*[^\*]+?\*/\s+", "")
  # Delete spaces around {}
  # one statement into {one statement}
  # if (asd) dsa
  # Small optimize
  data = data.replace(re2"(\.?)parent(\s*:?)", "$1p$2")
  data = data.replace(re2"\blastJSError\b", "le")
  data = data.replace(re2"\bprevJSError\b", "pe")
  if optSize:
    data = data.replace(re2"Uint32Array", "U32A")
    data = data.replace(re2"Int32Array", "I32A")
    data = data.replace(re2"Array", "A")
    data = data.replace(re2"Number", "N")
    data = data.replace(re2"String", "S")
    data = data.replace(re2"Math", "M")
    data = data.replace(re2"BigInt", "B")
    data = data.replace(
      re2"\A",
      "const M=Math;const S=String;const B=BigInt;const A=Array;" &
      "const U32A=Uint32Array;const I32A=Int32Array;const N=Number;"
    )
    data = data.replace(re2"true", "1")
    data = data.replace(re2"false", "0")
  # Compress expressions
  data = data.replace(re2"(else +if|while|for|if|do|else|switch)\s+", "$1")
  # Find variables and functions
  var
    counter = 0
    found: seq[string] = @[]
  for i in data.findAll(re2"\b\w+_\d+\b"):
    let j = data[i.group(0)]
    if j notin found:
      found.add(j)
      data = data.replace(j, fmt"a{counter}")
      inc counter
  # Find ConstSet, Temporary, Field, NTI\d+ and NNI\d+
  found = @[]
  counter = 0
  for i in data.findAll(re2"(ConstSet|Temporary|Field|N[TN]I)\d+"):
    let j = data[i.group(0)]
    if j notin found:
      found.add(j)
      data = data.replace(j, fmt"b{counter}")
      inc counter
  # Find functions
  found = @[]
  counter = 0
  for i in data.findAll(re2"function [c-z][a-zA-Z0-9_]*"):
    let j = data[i.group(0)]
    if j notin found:
      found.add(j)
      data = data.replace(j[9..^1], fmt" c{counter}")
      inc counter
  data = data.replace(re2"(size|base|node):\S+?,", "")
  data = data.replace(re2"filename:\S+?,", "")
  data = data.replace(re2"finalizer:\S+?}", "}")
  data = data.replace(re2"([;{}\]:,\(\)])\s+", "$1")
  data = data.replace(re2"  ", " ")
  data = data.replace(re2";;", ";")
  data = data.replace(
    re2"\s*([\-\+=<\|\*&>^/%!$\?]{1,3})\s*", "$1"
  )
  data = data.replace(
    re2"\[\s*", "["
  )
  f = open(project.buildDir / fmt"{SPA_MAIN_FILE}.js", fmWrite)
  f.write(data)
  f.close()
  styledEcho fgGreen, "✅ Build completed"
  shutdownCli()
  QuitSuccess


proc html2tagCommand(output: string = "", args: seq[string]): int =
  ## Converts HTML into `buildHtml` macro
  styledEcho fgGreen, "🔨 Convert HTML into happyx file"
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

  outputData = outputData.replace(re2"""( +)(tScript.*?:)\s+(\"{3})\s*([\s\S]+?)(\"{3})""", "$1$2 $3\n  $1$4$1$5")

  file = open(o, fmWrite)
  file.write(outputData)
  file.close()
  styledEcho fgGreen, "✅ Successfully!"
  shutdownCli()
  QuitSuccess


proc createCommand(name: string = "", kind: string = "", templates: bool = false,
                   pathParams: bool = false, useTailwind: bool = false, language: string = ""): int =
  ## Create command that asks user for project name and project type
  var
    projectName: string
    projectLanguage: string
    selected: int = 0
    selectedLang: int = 0
    imports = @["happyx"]
  let
    projectTypes = [
      "SSR", "SSG", "SPA", "HPX"
    ]
    projectTypesDesc = [
      "Server-side rendering ⚡",
      "Static site generation 📁",
      "Single-page application 🎴",
      "Single-page application with .hpx only ✨"
    ]
    programmingLanguages = [
      "nim", "python"
    ]
    programmingLanguagesDesc = [
      "Nim 👑", "Python 🐍"
    ]
  styledEcho "🔥 New ", fgBlue, styleBright, "HappyX", fgWhite, " project"
  if name == "":
    try:
      # Get project name
      styledWrite stdout, fgYellow, align("🔖 Project name: ", 14)
      projectName = readLine(stdin)
    except EOFError:
      styledEcho fgRed, "EOF error was occurred!"
      styledEcho fgYellow, "Please, try with flags:"
      styledEcho fgMagenta, "hpx create ", styleBright, "--name=app --kind=SPA"
      shutdownCli()
      return QuitFailure
    while projectName.len < 1 or projectName.contains(re2"[,!\\/':@~`]"):
      styledEcho fgRed, "Invalid name! It doesn't contains one of these symbols: , ! \\ / ' : @ ~ `"
      styledWrite stdout, fgYellow, align("Project name: ", 14)
      projectName = readLine(stdin)
  else:
    if projectName.contains(re2"[,!\\/':@~`]"):
      styledEcho fgRed, "Invalid name! It doesn't contains one of these symbols: , ! \\ / ' : @ ~ `"
      shutdownCli()
      return QuitFailure
    projectName = name

  if kind == "":
    styledEcho "👨‍🔬 Choose project type ", fgYellow, "(via arrow keys)"
    var
      choosen = false
      needRefresh = true
    while not choosen:
      if needRefresh:
        needRefresh = false
        for i, val in projectTypesDesc:
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
      shutdownCli()
      return QuitFailure

  if language == "":
    styledEcho "👨‍🔬 Choose project programming language ", fgYellow, "(via arrow keys)"
    var
      choosen = false
      needRefresh = true
    while not choosen:
      if needRefresh:
        needRefresh = false
        for i, val in programmingLanguagesDesc:
          if i == selectedLang:
            styledEcho styleUnderscore, fgGreen, "> ", val
          else:
            styledEcho fgYellow, "  ", val
      case getKey()
      of Key.Up, Key.ShiftH:
        if selectedLang > 0:
          needRefresh = true
          dec selectedLang
      of Key.Down, Key.ShiftP:
        if selectedLang < programmingLanguages.len-1:
          needRefresh = true
          inc selectedLang
      of Key.Enter:
        choosen = true
        break
      else:
        discard
      if needRefresh:
        for i in programmingLanguages:
          eraseLine(stdout)
          cursorUp(stdout)
  else:
    selectedLang = programmingLanguages.find(language.toLower())
    if selectedLang < 0:
      styledEcho fgRed, "Invalid project type! it should be one of these [", programmingLanguages.join(", "), "]"
      shutdownCli()
      return QuitFailure
  
  let lang = programmingLanguages[selectedLang]
  
  styledEcho "✨ Initializing project"
  createDir(projectName)
  createDir(projectName / "src")
  # Create .gitignore
  var f = open(projectName / ".gitignore", fmWrite)
  f.write("# Nimcache\nnimcache/\ncache/\nbuild/\n\n# Garbage\n*.exe\n*.js\n*.log\n*.lg")
  f.close()
  # Create README.md
  f = open(projectName / "README.md", fmWrite)
  f.write(
    "# " & projectName & "\n\n" & projectTypes[selected] &
    " project written in " & programmingLanguagesDesc[selectedLang] &
    " with HappyX ❤")
  f.close()

  # Write config
  f = open(projectName / CONFIG_FILE, fmWrite)
  f.write(
    "# HappyX project configuration.\n\n" &
    "[Main]\n" &
    "projectName = " & projectName & "\n" &
    "projectType = " & projectTypes[selected] & "\n" &
    "mainFile = main  # main script filename (without extension) that should be launched with hpx dev command\n" &
    "srcDir = src  # source directory in project root\n",
    "buildDir = build  # build directory in project root\n",
    "assetsDir = public  # assets directory in srcDir, will copied into build/public\n" &
    "language = " & programmingLanguages[selectedLang] & "  # programming language\n"
  )
  f.close()

  if pathParams:
    imports.add("path_params")
    case lang
    of "nim":
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
    case lang
    of "nim":
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
    of "python":
      f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.py", fmWrite)
      f.write(
        "# Import HappyX\n" &
        "from happyx import new_server, HttpRequest\n\n\n" &
        "# Just run python file to serve at http://localhost:5000\n" &
        "app = new_server('127.0.0.1', 5000)\n\n" &
        "# on GET method at http://localhost:5000/\n" &
        "@app.get('/')\n" &
        "def home():\n" &
        "    # Just return any data ✌\n" &
        "    return 'Hello, world!'\n"
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
  of 3:
    createDir(projectName / "src" / "public")
    createDir(projectName / "src" / "components")
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
    f = open(projectName / "src" / (SPA_MAIN_FILE & ".hpx"), fmWrite)
    f.write(
      "<template>\n" &
      "  <HelloWorld></HelloWorld>\n" &
      "</template>\n\n"
    )
    f.close()
    f = open(projectName / "src" / "router.json", fmWrite)
    f.write(
      "{\n" &
      "  \"/\": \"main.hpx\"\n" &
      "}"
    )
    f.close()
    f = open(projectName / "src" / "components" / "HelloWorld.hpx", fmWrite)
    f.write(
      "<template>\n" &
      "  <div>\n" &
      "    Hello, world!\n" &
      "  </div>\n" &
      "</template>\n\n" &
      "<script>\n" &
      "  echo \"Hello, world!\"\n" &
      "</script>\n\n" &
      "<style>\n" &
      "  div {\n" &
      "    background-color: #242118;\n" &
      "    color: #fece8e;\n" &
      "    padding: .2rem;\n" &
      "  }\n" &
      "</style>\n"
    )
    f.close()
  else:
    discard
  # Tell user about choosen
  case lang
  of "nim":
    styledEcho fgYellow, "🐥 You choose ", fgMagenta, "Nim 👑", fgYellow, " programming language for this project."
  of "python":
    styledEcho fgYellow, "🐥 You choose ", fgMagenta, "Python 🐍", fgYellow, " programming language for this project."
  if useTailwind:
    styledEcho fgYellow, "🐥 You choose ", fgMagenta, "tailwind css", fgYellow, " on project creation. Read docs: ", styleUnderscore, fgGreen, "https://tailwindcss.com/docs/"
  if templates:
    styledEcho fgYellow, "🐥 You enabled ", fgMagenta, "templates", fgYellow, " on project creation. Read more: ", styleUnderscore, fgGreen, "https://github.com/enthus1ast/nimja"
  styledEcho fgGreen, "⚡ Successfully created ", fgMagenta, projectName, fgGreen, " project!"
  shutdownCli()
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
  
  if project.error.len > 0:
    shutdownCli()
    return QuitFailure

  if reload:
    initLock(L)
    createThread(godEyeThread, godEye, addr godEyeData)

  # Launch SSR app
  if project.projectType in [ptSSG, ptSSR]:
    styledEcho fgRed, "❌ SSR/SSG projects not available in the dev mode."
    styledEcho fgMagenta, "💡 Make SSR/SSG dev mode and send Pull Request if you want!"
    shutdownCli()
    return QuitSuccess

  # Start server for SPA
  styledEcho "⚡ Server launched at ", fgGreen, styleUnderscore, "http://", host, ":", $port, fgWhite
  openDefaultBrowser("http://" & host & ":" & $port & "/#/")

  serve host, port:
    get "/":
      let f = open(getCurrentDir() / project.srcDir / "index.html")
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
        "setInterval(intervalSending, 1000);\n" &
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
      let path = getCurrentDir() / project.srcDir / file.replace('\\', '/').replace('/', DirSep)
      echo "File: ", file
      echo "Path: ", path
      if fileExists(path):
        await req.answerFile(path)
  shutdownCli()
  QuitSuccess


proc serveCommand(host: string = "0.0.0.0", port: int = 80): int =
  ## Serve SPA for production
  var
    project = compileProject()
  
  if project.error.len > 0:
    return QuitFailure

  # Explain SSG Error
  if project.projectType in [ptSSG, ptSSR]:
    styledEcho fgYellow, "❌ SSG projects not required to be supported in serve mode."
    styledEcho fgMagenta, "💡 Compile and run your SSG server!"
    shutdownCli()
    return QuitSuccess

  # Start SPA server
  styledEcho "🔥 Server launched at ", fgGreen, styleUnderscore, "http://", host, ":", $port, fgWhite
  
  serve host, port:
    get "/":
      let f = open(getCurrentDir() / "build" / "index.html")
      var data = f.readAll()
      f.close()
      req.answerHtml(data)
 
    get "/{file:path}":
      var result = ""
      let path = getCurrentDir() / "build" / file.replace('\\', '/').replace('/', DirSep)
      echo "File: ", file
      echo "Path: ", path
      if fileExists(path):
        await req.answerFile(path)
  shutdownCli()
  QuitSuccess


proc mainCommand(version = false): int =
  if version:
    styledEcho "HappyX ", fgGreen, HpxVersion
  else:
    mainHelpMessage()
  shutdownCli()
  QuitSuccess


when isMainModule:
  illwillInit(false)
  dispatchMultiGen(
    [buildCommand, cmdName = "build"],
    [devCommand, cmdName = "dev"],
    [serveCommand, cmdName = "serve"],
    [createCommand, cmdName = "create"],
    [html2tagCommand, cmdName = "html2tag"],
    [updateCommand, cmdName = "update"],
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
  of "update":
    quit(dispatchupdate(cmdline = pars[1..^1]))
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
    of "serve":
      styledEcho fgBlue, "HappyX", fgMagenta, " serve ", fgWhite, "command starting product server for SPA project."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "hpx dev\n"
      styledEcho "Optional arguments:"
      styledEcho align("host", 8), "|h - change address (default is 0.0.0.0) (ex. --host:0.0.0.0)"
      styledEcho align("port", 8), "|p - change port (default is 80) (ex. --port:80)"
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
    of "update":
      styledEcho fgBlue, "HappyX", fgMagenta, " update ", fgWhite, "command updates happyx framework."
      styledEcho "\nUsage:"
      styledEcho fgMagenta, "hpx update VERSION\n"
    else:
      styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmdHelp
    shutdownCli()
    quit(QuitSuccess)
  of "":
    quit(dispatchmainCommand(cmdline = pars[0..^1]))
  else:
    styledEcho fgRed, "Unknown subcommand: ", fgWhite, subcmd
    shutdownCli()
    quit(QuitFailure)
