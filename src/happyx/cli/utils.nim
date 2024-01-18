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
  std/times,
  std/math,
  std/algorithm,
  std/os,
  std/json,
  std/strformat,
  std/osproc,
  std/locks,
  std/sugar,
  # thirdparty
  regex,
  ../../happyx


import illwill except
  fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue,
  bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


export
  os, osproc, terminal, htmlparser,
  xmltree, locks, sugar, strformat, strutils,
  algorithm, asyncdispatch, browsers,
  happyx,
  regex


type
  ProjectType* {.pure, size: sizeof(int8).} = enum
    ptSPA = "SPA",
    ptSPA_PWA = "SPA+PWA",
    ptSSG = "SSG",
    ptSSR_PWA = "SSR+PWA",
    ptSSR = "SSR",
    ptSPAHpx = "HPX"
  ProgrammingLanguage* {.pure, size: sizeof(int8).} = enum
    plNim = "nim",
    plPython = "python",
    plJavaScript = "javascript",
    plTypeScript = "typescript"
  ProjectData* = object
    process*: Process
    mainFile*: string  ## Main file without extension
    srcDir*: string  ## Source directory
    projectType*: ProjectType  ## Project type (SPA/SSR/SSG)
    error*: string
    assetsDir*: string  ## Assets directory
    buildDir*: string  ## Build directory
    language*: ProgrammingLanguage
    name*: string
  GodEyeData* = object
    needReload*: ptr bool
    project*: ptr ProjectData
  Progress* = ref object
    state*: string


const
  SPA_MAIN_FILE* = "main"
  CONFIG_FILE* = "happyx.cfg"
  PROGRESS_STATES* = ["|", "/", "-", "\\"]
  PROCESS_OPTIONS*: set[ProcessOption] =
    when defined(windows):
      {poStdErrToStdOut}
    else:
      {poStdErrToStdOut, poUsePath}


var
  projectTypes*: array[6, string]
  tailwindList*: array[2, string]
  templatesList*: array[2, string]
  projectTypesDesc*: array[6, string]
  programmingLanguages*: array[4, string]
  programmingLanguagesDesc*: array[4, string]


var
  godEyeThread*: Thread[ptr GodEyeData]
  L*: Lock
  deinitialized* = false
  useEmoji* = true
  emoji* = {
    "🔥": proc(): string = (if useEmoji: "🔥" else: ""),
    "🐥": proc(): string = (if useEmoji: "🐥" else: ""),
    "✨": proc(): string = (if useEmoji: "✨" else: ""),
    "👨‍🔬": proc(): string = (if useEmoji: "👨‍🔬" else: ""),
    "🧪": proc(): string = (if useEmoji: "🧪" else: ""),
    "🎨": proc(): string = (if useEmoji: "🎨" else: ""),
    "✌": proc(): string = (if useEmoji: "✌" else: ""),
    "⚡": proc(): string = (if useEmoji: "⚡" else: ""),
    "📁": proc(): string = (if useEmoji: "📁" else: ""),
    "🔨": proc(): string = (if useEmoji: "🔨" else: ""),
    "📦": proc(): string = (if useEmoji: "📦" else: ""),
    "🔌": proc(): string = (if useEmoji: "🔌" else: ""),
    "🐲": proc(): string = (if useEmoji: "🐲" else: ""),
    "❎": proc(): string = (if useEmoji: "❎" else: ""),
    "✅": proc(): string = (if useEmoji: "✅" else: ""),
    "👑": proc(): string = (if useEmoji: "👑" else: ""),
    "🐍": proc(): string = (if useEmoji: "🐍" else: ""),
    "💡": proc(): string = (if useEmoji: "💡" else: ""),
    "😸": proc(): string = (if useEmoji: "😸" else: ""),
    "❌": proc(): string = (if useEmoji: "❌" else: ""),
  }.toTable()


proc init*() =
  projectTypes = [
    "SSR",
    "SSR+PWA",
    "SSG",
    "SPA",
    "SPA+PWA",
    "HPX"
  ]
  tailwindList = [
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgGreen) & "use tailwindcss 3" & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgRed) & "don't use tailwindcss 3" & ansiResetCode,
  ]
  templatesList = [
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgGreen) & "use templates" & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgRed) & "don't use templates" & ansiResetCode,
  ]
  projectTypesDesc = [
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgGreen) & "Server-side rendering " & emoji["⚡"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgGreen) & "Server-side rendering with PWA " & emoji["⚡"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgBlue) & "Static site generation " & emoji["📦"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgYellow) & "Single-page application " & emoji["✨"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgYellow) & "Single-page application with PWA " & emoji["✨"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgRed) & "Single-page application with .hpx only " & emoji["🧪"]() & ansiResetCode,
  ]
  programmingLanguages = [
    "nim",
    "python",
    "javascript",
    "typescript"
  ]
  programmingLanguagesDesc = [
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgRed) & "Nim " & emoji["👑"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgMagenta) & "Python " & emoji["🐍"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgYellow) & "JavaScript " & emoji["✌"]() & ansiResetCode,
    ansiStyleCode(styleBright) & ansiForegroundColorCode(fgBlue) & "TypeScript " & emoji["🔥"]() & ansiResetCode,
  ]


proc shutdownCli* =
  if deinitialized:
    return
  deinitialized = true
  illwillDeinit()
  deinitLock(L)


proc ctrlC* {. noconv .} =
  ## Hook for Ctrl+C
  shutdownCli()
  quit(QuitSuccess)

addExitProc(ctrlC)


proc initProgress*: Progress = Progress(state: "|")

proc nextState*(self: Progress): string =
  var idx = PROGRESS_STATES.find(self.state)
  if idx < PROGRESS_STATES.len - 1:
    inc idx
  else:
    idx = 0
  self.state = PROGRESS_STATES[idx]
  self.state


proc isProject*(): bool =
  fileExists(getCurrentDir() / CONFIG_FILE)


proc readConfig*(): ProjectData =
  result = ProjectData(
      projectType: ptSPA, srcDir: "src",
      mainFile: SPA_MAIN_FILE,
      process: nil, error: "",
      assetsDir: "public",
      buildDir: "build", name: ""
    )
  if fileExists(getCurrentDir() / CONFIG_FILE):
    let cfg = loadConfig(getCurrentDir() / CONFIG_FILE)
    result.projectType = parseEnum[ProjectType](
      cfg.getSectionValue("Main", "projectType", "SPA").toUpper()
    )
    result.language = parseEnum[ProgrammingLanguage](
      cfg.getSectionValue("Main", "language", "nim").toLower()
    )
    result.mainFile = cfg.getSectionValue("Main", "mainFile", SPA_MAIN_FILE)
    result.srcDir = cfg.getSectionValue("Main", "srcDir", "src")
    result.assetsDir = cfg.getSectionValue("Main", "assetsDir", "public")
    result.buildDir = cfg.getSectionValue("Main", "buildDir", "build")
    result.name = cfg.getSectionValue("Main", "projectName", "")


proc compileProject*(): ProjectData {. discardable .} =
  ## Compiling Project
  result = readConfig()
  let
    file1 = getCurrentDir() / result.srcDir / (result.mainFile & ".nim")
    file2 = getCurrentDir() / result.srcDir / (result.mainFile)
  if not (fileExists(file1) or fileExists(file2)):
    styledEcho fgRed, "current directory is not HappyX project."
    quit QuitFailure

  case result.projectType:
  of ptSPA, ptSPA_PWA:
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
        compName = compName[0..^5]
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
          of "pathparam", "path":
            f.write(fmt"""{key}={arg["name"].getStr},""")
          of "query":
            f.write(fmt"""{key}=query~{arg["name"].getStr},""")
          of "queryarr", "queryarray":
            f.write(fmt"""{key}=queryArr~{arg["name"].getStr},""")
        else:
          raise newException(ValueError, fmt"Incorrect router.json structure at `{key}`")
      f.write(")\n\n")
    f.close()
    # just for debug
    # f = open(result.srcDir / result.mainFile & ".nim", fmRead)
    # echo f.readAll()
    # f.close()
    result.process = startProcess(
      "nim", getCurrentDir() / result.srcDir,
      [
        "js", "-c", "--hints:off", "--warnings:off",
        "--opt:size", "-d:danger", "-x:off", "-a:off", "--panics:off", "--lineDir:off", result.mainFile
      ], nil, PROCESS_OPTIONS
    )
  of ptSSR, ptSSG, ptSSR_PWA:
    result.process = startProcess(
      "nim", getCurrentDir() / result.srcDir,
      [
        "c", "--hints:off", "--warnings:off",
        "--opt:size", "-d:danger", "-x:off", "-a:off", "--panics:off", "--lineDir:off", result.mainFile
      ], nil, PROCESS_OPTIONS
    )

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
  if result.process.peekExitCode < 1:
    styledEcho fgGreen, "Successfully compiled ", fgMagenta, result.mainFile, "                     "
    for line in lines:
      echo line
  else:
    styledEcho fgRed, "An error was occurred when compiling ", fgMagenta, result.mainFile, "        "
    for line in lines:
      echo line
      result.error &= line
  if not result.process.isNil():
    result.process.close()
  if result.projectType == ptSPAHpx:
    removeFile(result.srcDir / result.mainFile & ".nim")
  if result.projectType in [ptSSR, ptSSG, ptSSR_PWA]:
    when defined(windows):
      result.process = startProcess(
        getCurrentDir() / result.srcDir / (result.mainFile & ".exe"),
        options = {poEchoCmd, poEvalCommand, poStdErrToStdOut, poUsePath}
      )
    else:
      result.process = startProcess(
        result.mainFile, getCurrentDir() / result.srcDir,
        options = {poEvalCommand, poStdErrToStdOut}
      )


proc godEye*(arg: ptr GodEyeData) {. thread, nimcall .} =
  ## Got eye that watch all changes in your project files
  let directory = getCurrentDir()
  var
    lastCheck: seq[tuple[path: string, time: times.Time]] = @[]
    currentCheck: seq[tuple[path: string, time: times.Time]] = @[]
  
  for file in directory.walkDirRec():
    lastCheck.add((path: file, time: file.getFileInfo().lastWriteTime))
  
  let
    mainFile = arg[].project[].mainFile
    projectType = arg[].project[].projectType
  
  while true:
    # Get file write times
    for file in directory.walkDirRec():
      if file.endsWith("linkerArgs.txt"):
        continue
      currentCheck.add((path: file, time: file.getFileInfo().lastWriteTime))
    # Check
    if currentCheck.len != lastCheck.len:
      acquire(L)
      styledEcho fgGreen, "Changing found ", fgWhite, " reloading ..."
      release(L)
      if projectType in [ptSSR, ptSSG, ptSSR_PWA] and not arg[].project[].process.isNil:
        let id = arg[].project[].process.processID()
        when defined(windows):
          discard execCmd(fmt"taskkill /F /PID {id}")
        elif defined(linux):
          discard execCmd(fmt"kill {id}")
        elif defined(macos) or defined(macosx):
          discard execCmd(fmt"kill -9 {id}")
      arg[].project[] = compileProject()
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
          if projectType in [ptSSR, ptSSG, ptSSR_PWA] and not arg[].project[].process.isNil:
            let id = arg[].project[].process.processID()
            when defined(windows):
              discard execCmd(fmt"taskkill /F /PID {id}")
            elif defined(linux):
              discard execCmd(fmt"kill {id}")
            elif defined(macos) or defined(macosx):
              discard execCmd(fmt"kill -9 {id}")
          arg[].project[] = compileProject()
          arg[].needReload[] = true
      lastCheck = @[]
      for i in currentCheck:
        lastCheck.add(i)
      currentCheck = @[]
    sleep(20)


proc xml2Text*(xml: XmlNode): string =
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


proc xmlTree2Text*(data: var string, tree: XmlNode, lvl: int = 2) =
  let text = tree.xml2Text()
  if text.len > 0:
    data &= ' '.repeat(lvl) & tree.xml2Text() & "\n"
  
  if tree.kind == xnElement:
    for child in tree.items:
      data.xmlTree2Text(child, lvl+2)


proc updateHappyx*(version: string) =
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
  styledEcho fgMagenta, emoji["✨"](), " HappyX ", fgGreen, "successfully updated to ", fgMagenta, version


proc minifyJs*(jsCode: string): string =
  result = jsCode
  let
    keywords = @[
      "import", "export", "default", "from",
      "if", "else", "return",
      "var", "const", "let",
      "for", "switch", "case", "break", "continue", "do", "while",
      "typeof", "instanceof",
      "new",
      "try", "catch", "finally", "throw",
      "class", "extends", "super",
      "this",
      "true", "false", "null", "undefined", "NaN",
      "async", "await"
    ]
  echo result.len.int64.formatSize(prefix = bpColloquial, includeSpace = true)
  result = result.replace(re2"(else +if|while|for|if|do|else|switch)\s+", "$1")
  result = result.replace(re2"\blastJSError\b", "le")
  result = result.replace(re2"\bprevJSError\b", "pe")
  result = result.replace("  ", " ")
  # Find and replace all variables, functions, etc
  eraseLine()
  cursorUp()
  echo alignLeft($result.len.int64.formatSize(prefix = bpColloquial, includeSpace = true), 24)
  var
    counter = 0
    found: seq[string] = @[]
    minSize = int.high
  for i in result.findAll(re2("\\b(\\w+_[\\w\\d]+)\\b(?!\\.)")):
    let j = result[i.group(0)]
    if j notin found:
      found.add(j)
      found.add(fmt"a{counter}")
      result = result.replace(j, fmt"a{counter}")
      inc counter
      eraseLine()
      cursorUp()
      echo alignLeft($result.len.int64.formatSize(prefix = bpColloquial, includeSpace = true), 24)
  # Find ConstSet, Temporary, Field, NTI\d+ and NNI\d+
  found = @[]
  counter = 0
  for i in result.findAll(re2"(ConstSet|Temporary|Field|N[TN]I)\d+"):
    let j = result[i.group(0)]
    if j notin found:
      found.add(j)
      result = result.replace(j, fmt"b{counter}")
      inc counter
      eraseLine()
      cursorUp()
      echo alignLeft($result.len.int64.formatSize(prefix = bpColloquial, includeSpace = true), 24)
  # Find functions
  found = @[]
  counter = 0
  for i in result.findAll(re2"function ([c-z][a-zA-Z0-9_])*"):
    let j = result[i.group(0)]
    if j notin found:
      found.add(j)
      result = result.replace(j[9..^1], fmt" c{counter}")
      inc counter
      eraseLine()
      cursorUp()
      echo alignLeft($result.len.int64.formatSize(prefix = bpColloquial, includeSpace = true), 24)
