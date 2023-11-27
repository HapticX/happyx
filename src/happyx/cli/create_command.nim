import
  ./[utils, consts]


import illwill except
  fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue,
  bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


proc makeJsPackageJson*(projectName: string) =
  var f = open(projectName / "package.json", fmWrite)
  let username = getHomeDir().lastPathPart()
  f.write(fmt(packageJson))
  f.close()


proc makeTsPackageJson*(projectName: string) =
  var f = open(projectName / "package.json", fmWrite)
  let username = getHomeDir().lastPathPart()
  f.write(fmt(packageJson))
  f = open(projectName / "tsconfig.json", fmWrite)
  f.write(typescriptConfig)
  f.close()


proc chooseFrom*(target, views: openArray[string]): int =
  result = 0
  var
    choosen = false
    needRefresh = true
  while not choosen:
    if needRefresh:
      needRefresh = false
      for i, val in views:
        if i == result:
          styledEcho styleUnderscore, fgGreen, "> ", val
        else:
          styledEcho fgYellow, "  ", val
    case getKey()
    of Key.Up, Key.ShiftH:
      if result > 0:
        needRefresh = true
        dec result
    of Key.Down, Key.ShiftP:
      if result < target.len-1:
        needRefresh = true
        inc result
    of Key.Enter:
      choosen = true
      needRefresh = false
      break
    else:
      discard
    if needRefresh:
      for i in target:
        eraseLine(stdout)
        cursorUp(stdout)


proc createCommand*(name: string = "", kind: string = "", templates: bool = false,
                    pathParams: bool = false, useTailwind: bool = false,
                    language: string = ""): int =
  ## Create command that asks user for project name and project type
  var
    projectName: string
    projectLanguage: string
    selected: int = 0
    selectedLang: int = 0
    selectedTailwind: int = 0
    selectedTemplates = 0
    imports = @["happyx"]
    useTailwind = useTailwind
    templates = templates
  styledEcho emoji["🔥"](), " New ", fgBlue, styleBright, "HappyX", fgWhite, " project"
  if name == "":
    try:
      # Get project name
      styledWrite stdout, fgYellow, align("\n" & emoji["🧪"]() & " Project name: ", 14)
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
    echo ""
    styledEcho emoji["🐲"](), " Choose project type ", fgYellow, "(via arrow keys)"
    selected = chooseFrom(projectTypes, projectTypesDesc)
  else:
    selected = projectTypes.find(kind.toUpper())
    if selected < 0:
      styledEcho fgRed, "Invalid project type! it should be one of these [", projectTypes.join(", "), "]"
      shutdownCli()
      return QuitFailure

  if language == "":
    if selected > 2:
      # Only for Nim
      echo ""
      styledEcho emoji["🐲"](), " You choose project type that allowed only for Nim."
      styledEcho emoji["🐥"](), " Nim language was choosed."
      selectedLang = 0
    else:
      echo ""
      styledEcho emoji["🐲"](), " Choose project programming language ", fgYellow, "(via arrow keys)"
      selectedLang = chooseFrom(programmingLanguages, programmingLanguagesDesc)
  else:
    selectedLang = programmingLanguages.find(language.toLower())
    if selectedLang < 0:
      styledEcho fgRed, "Invalid project type! it should be one of these [", programmingLanguages.join(", "), "]"
      shutdownCli()
      return QuitFailure
  
  let
    lang = programmingLanguages[selectedLang]
    projectType = projectTypes[selected]
  
  if lang == "nim" and projectType in ["SSR", "SSG"]:
    echo ""
    styledEcho emoji["🔥"](), " Do you want to use templates in your project? "
    selectedTemplates = chooseFrom(templatesList, templatesList)
    templates = selectedTemplates == 0
  elif projectType == "SSR+PWA":
    echo ""
    styledEcho emoji["💡"](), " you choose ", fgRed, "SSR + PWA ", fgWhite, "project type so templates was been enabled"
    templates = true
  elif lang == "nim" and projectType in ["SPA", "HPX", "SPA+PWA"]:
    echo ""
    styledEcho emoji["🐲"](), " Do you want to use Tailwind CSS in your project? "
    selectedTailwind = chooseFrom(tailwindList, tailwindList)
    useTailwind = selectedTailwind == 0
  
  styledEcho emoji["✨"](), " Initializing project ... /"
  createDir(projectName)
  createDir(projectName / "src")
  # Create .gitignore
  var f = open(projectName / ".gitignore", fmWrite)
  case lang
  of "nim":
    f.write(nimGitignore)
  of "python":
    f.write(pyGitignore)
  of "javascript", "typescript":
    f.write(nodeGitignore)
  f.close()
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho emoji["✨"](), " Initializing project ... |"
  # Create README.md
  f = open(projectName / "README.md", fmWrite)
  f.write(fmt(readmeTemplate))
  f.close()
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho emoji["✨"](), " Initializing project ... \\"

  # Write config
  f = open(projectName / CONFIG_FILE, fmWrite)
  f.write(fmt(configString))
  f.close()
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho emoji["✨"](), " Initializing project ... -"

  if pathParams:
    imports.add("path_params")
    case lang
    of "nim":
      f = open(projectName / "src" / "path_params.nim", fmWrite)
      f.write("import happyx\n\n\npathParams:\n  id int\n")
      f.close()
  
  let isPwa = selected in {1, 4}
  case selected
  of 0, 1, 2:
    # SSR/SSR+PWA/SSG
    createDir(projectName / "src" / "public")
    if isPwa:
      createDir(projectName / "src" / "pwa")
      f = open(projectName / "src" / "pwa" / "manifest.json", fmWrite)
      f.write(spaPwaManifest)
      f.close()
      f = open(projectName / "src" / "pwa" / "service_worker.js", fmWrite)
      f.write(spaServiceWorkerTemplate)
      f.close()
    if templates:
      styledEcho fgYellow, "Templates in SSR was enabled. To disable it remove --templates flag."
      createDir(projectName / "src" / "templates")
      f = open(projectName / "src" / "templates" / "index.html", fmWrite)
      if isPwa:
        f.write(nimjaPwaTemplate)
      else:
        f.write(nimjaTemplate)
      f.close()
    else:
      styledEcho fgYellow, "Templates in SSR was disabled. To enable it add --templates flag."
    # Create main file
    case lang
    of "nim":
      f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
      if templates and isPwa:
        f.write(fmt(ssrTemplatePwaNinja))
      elif templates:
        f.write(fmt(ssrTemplateNinja))
      else:
        f.write(fmt(ssrTemplate))
    of "python":
      f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.py", fmWrite)
      f.write(pyTemplate)
    of "javascript":
      f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.js", fmWrite)
      f.write(jsTemplate)
      makeJsPackageJson(projectName)
    of "typescript":
      f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.ts", fmWrite)
      f.write(tsTemplate)
      makeTsPackageJson(projectName)
    f.close()
  of 3, 4:
    # SPA + PWA
    imports.add("components/[hello_world]")
    createDir(projectName / "src" / "public")
    createDir(projectName / "src" / "components")
    f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.nim", fmWrite)
    f.write(fmt(spaTemplate))
    f.close()
    f = open(projectName / "src" / "index.html", fmWrite)
    var additionalHead = ""
    if useTailwind:
      additionalHead &= "<script src=\"https://cdn.tailwindcss.com\"></script>\n    "
    if isPwa:
      f.write(fmt(spaPwaIndexTemplate))
    else:
      f.write(fmt(spaIndexTemplate))
    f.close()
    if isPwa:
      f = open(projectName / "src" / "service_worker.js", fmWrite)
      f.write(spaServiceWorkerTemplate)
      f.close()
      f = open(projectName / "src" / "manifest.json", fmWrite)
      f.write(fmt(spaPwaManifest))
      f.close()
    f = open(projectName / "src" / "components" / "hello_world.nim", fmWrite)
    f.write(componentTemplate)
    f.close()
  of 5:
    # HPX
    createDir(projectName / "src" / "public")
    createDir(projectName / "src" / "components")
    f = open(projectName / "src" / "index.html", fmWrite)
    var additionalHead = ""
    if useTailwind:
      additionalHead &= "<script src=\"https://cdn.tailwindcss.com\"></script>\n  "
    f.write(fmt(spaIndexTemplate))
    f.close()
    f = open(projectName / "src" / (SPA_MAIN_FILE & ".hpx"), fmWrite)
    f.write(hpxTemplate)
    f.close()
    f = open(projectName / "src" / "router.json", fmWrite)
    f.write(hpxRouterTemplate)
    f.close()
    f = open(projectName / "src" / "components" / "HelloWorld.hpx", fmWrite)
    f.write(hpxComponentTemplate)
    f.close()
  else:
    discard
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho "✨ Project initialized ", " ".repeat(24)

  # Tell user about choosen
  styledEcho fgYellow, emoji["🐥"](), " You choose ", fgMagenta, programmingLanguagesDesc[selectedLang], fgYellow, " programming language for this project."
  if useTailwind:
    styledEcho fgYellow, emoji["🐥"](), " You choose ", fgMagenta, "tailwind css", fgYellow, " on project creation. Read docs: ", styleUnderscore, fgGreen, "https://tailwindcss.com/docs/"
  if templates:
    styledEcho fgYellow, emoji["🐥"](), " You enabled ", fgMagenta, "templates", fgYellow, " on project creation. Read more: ", styleUnderscore, fgGreen, "https://github.com/enthus1ast/nimja"
  styledEcho fgGreen, emoji["⚡"](), " Successfully created ", fgMagenta, projectName, fgGreen, " project!"

  shutdownCli()
  QuitSuccess
