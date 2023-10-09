import
  ./utils


import illwill except
  fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue,
  bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


proc makeJsPackageJson*(projectName: string) =
  var f = open(projectName / "package.json", fmWrite)
  let username = getHomeDir().lastPathPart()
  f.write(
    "{\n" &
    "  \"name\": \"happyx-project\",\n" &
    "  \"description\": \"Yet another NodeJS HappyX project\",\n" &
    "  \"version\": \"1.0.0\",\n" &
    "  \"author\": \"" & username & "\",\n" &
    "  \"type\": \"module\",\n" &
    "  \"main\": \"src/index.ts\",\n" &
    "  \"keywords\": [],\n" &
    "  \"license\": \"MIT\",\n" &
    "  \"dependencies\": {\n" &
    "    \"happyx\": \"^1.0.8\"\n" &
    "  }\n" &
    "}"
  )
  f.close()


proc makeTsPackageJson*(projectName: string) =
  var f = open(projectName / "package.json", fmWrite)
  let username = getHomeDir().lastPathPart()
  f.write(
    "{\n" &
    "  \"name\": \"happyx-project\",\n" &
    "  \"description\": \"Yet another NodeJS HappyX project\",\n" &
    "  \"version\": \"1.0.0\",\n" &
    "  \"author\": \"" & username & "\",\n" &
    "  \"type\": \"module\",\n" &
    "  \"main\": \"src/index.js\",\n" &
    "  \"keywords\": [],\n" &
    "  \"license\": \"MIT\",\n" &
    "  \"dependencies\": {\n" &
    "    \"happyx\": \"^1.0.8\",\n" &
    "    \"typescript\": \"^5.2.2\"\n" &
    "  }\n" &
    "}"
  )
  f = open(projectName / "tsconfig.json", fmWrite)
  f.write(
    "{\n" &
    "  \"compilerOptions\": {\n" &
    "    \"moduleDetection\": \"auto\",\n" &
    "    \"target\": \"ES6\",\n" &
    "    \"module\": \"CommonJS\",\n" &
    "    \"outDir\": \"./build\",\n" &
    "    \"rootDir\": \"./src\",\n" &
    "    \"checkJs\": true,\n" &
    "    \"strictNullChecks\": true,\n" &
    "    \"strictFunctionTypes\": true,\n" &
    "    \"strictBindCallApply\": true,\n" &
    "    \"strictPropertyInitialization\": true,\n" &
    "    \"noImplicitThis\": true,\n" &
    "    \"alwaysStrict\": true,\n" &
    "    \"noPropertyAccessFromIndexSignature\": true,\n" &
    "    \"esModuleInterop\": true,\n" &
    "    \"forceConsistentCasingInFileNames\": true,\n" &
    "    \"skipLibCheck\": true,\n" &
    "    \"noImplicitOverride\": true,\n" &
    "    \"noFallthroughCasesInSwitch\": true,\n" &
    "    \"noImplicitReturns\": true,\n" &
    "    \"noImplicitAny\": false,\n" &
    "    \"strict\": true,\n" &
    "    \"noEmit\": false,\n" &
    "    \"allowJs\": true\n" &
    "  }\n" &
    "}"
  )
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
      break
    else:
      discard
    if needRefresh:
      for i in target:
        eraseLine(stdout)
        cursorUp(stdout)


proc createCommand*(name: string = "", kind: string = "", templates: bool = false,
                    pathParams: bool = false, useTailwind: bool = false, language: string = ""): int =
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
  styledEcho "🔥 New ", fgBlue, styleBright, "HappyX", fgWhite, " project"
  if name == "":
    try:
      # Get project name
      styledWrite stdout, fgYellow, align("\n🔖 Project name: ", 14)
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
    styledEcho "\n🐲 Choose project type ", fgYellow, "(via arrow keys)"
    selected = chooseFrom(projectTypes, projectTypesDesc)
  else:
    selected = projectTypes.find(kind.toUpper())
    if selected < 0:
      styledEcho fgRed, "Invalid project type! it should be one of these [", projectTypes.join(", "), "]"
      shutdownCli()
      return QuitFailure

  if language == "":
    styledEcho "\n🐲 Choose project programming language ", fgYellow, "(via arrow keys)"
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
    styledEcho "\n🐲 Are you want to use templates in your project? "
    selectedTemplates = chooseFrom(templatesList, templatesList)
    templates = selectedTemplates == 0
  elif lang == "nim" and projectType in ["SPA", "HPX"]:
    styledEcho "\n🐲 Are you want to use Tailwind CSS in your project? "
    selectedTailwind = chooseFrom(tailwindList, tailwindList)
    useTailwind = selectedTailwind == 0
  
  styledEcho "✨ Initializing project ... /"
  createDir(projectName)
  createDir(projectName / "src")
  # Create .gitignore
  var f = open(projectName / ".gitignore", fmWrite)
  case lang
  of "nim":
    f.write(
      "# Nimcache\nnimcache/\ncache/\nbuild/\n\n# Garbage\n*.exe\n*.js\n*.log\n*.lg"
    )
  of "python":
    f.write(
      "# Python cache\n__pycache__/\nbuild/\n\n# Logs\n*.log\n*.lg"
    )
  of "javascript", "typescript":
    f.write(
      "# Node cache\nnode_modules/\npackage-lock.json\nyarn.lock"
    )
  f.close()
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho "✨ Initializing project ... |"
  # Create README.md
  f = open(projectName / "README.md", fmWrite)
  f.write(
    "# " & projectName & "\n\n" & projectTypes[selected] &
    " project written in " & lang &
    " with HappyX ❤")
  f.close()
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho "✨ Initializing project ... \\"

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
    "language = " & lang & "  # programming language\n"
  )
  f.close()
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho "✨ Initializing project ... -"

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
    of "javascript":
      f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.js", fmWrite)
      f.write(
        "// Import HappyX\n" &
        "import { Server } from \"happyx\";\n\n" &
        "const app = new Server(\"127.0.0.1\", 5000);\n\n" &
        "// Register GET route at http://127.0.0.1:5000/\n" &
        "app.get(\"/\", (req) => {\n" &
        "  return \"Hello, world!\";\n" &
        "});\n\n" &
        "// start app\n" &
        "app.start();\n"
      )
      makeJsPackageJson(projectName)
    of "typescript":
      f = open(projectName / "src" / fmt"{SPA_MAIN_FILE}.ts", fmWrite)
      f.write(
        "// Import HappyX\n" &
        "import { Server, Request } from \"happyx\";\n\n" &
        "const app = new Server(\"127.0.0.1\", 5000);\n\n" &
        "// Register GET route at http://127.0.0.1:5000/\n" &
        "app.get(\"/\", (req: Request) => {\n" &
        "  return \"Hello, world!\";\n" &
        "});\n\n" &
        "// start app\n" &
        "app.start();\n"
      )
      makeTsPackageJson(projectName)
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
  eraseLine(stdout)
  cursorUp(stdout)
  styledEcho "✨ Project initialized       "

  # Tell user about choosen
  styledEcho fgYellow, "🐥 You choose ", fgMagenta, programmingLanguagesDesc[selectedLang], fgYellow, " programming language for this project."
  if useTailwind:
    styledEcho fgYellow, "🐥 You choose ", fgMagenta, "tailwind css", fgYellow, " on project creation. Read docs: ", styleUnderscore, fgGreen, "https://tailwindcss.com/docs/"
  if templates:
    styledEcho fgYellow, "🐥 You enabled ", fgMagenta, "templates", fgYellow, " on project creation. Read more: ", styleUnderscore, fgGreen, "https://github.com/enthus1ast/nimja"
  styledEcho fgGreen, "⚡ Successfully created ", fgMagenta, projectName, fgGreen, " project!"

  shutdownCli()
  QuitSuccess