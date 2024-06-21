import
  ./utils


proc projectInfoCommand*(): int =
  if not isProject():
    styledEcho fgRed, "Current folder is not HappyX project. ", emoji["❌"]()
    return QuitFailure
  var projectData = readConfig()
  styledEcho fgMagenta, styleBright, emoji["🔥"](), " Project name: ", fgGreen, projectData.name
  styledEcho fgMagenta, styleBright, emoji["✌"](), " Project type: ", projectTypesDesc[
    projectTypes.find($projectData.projectType)
  ]
  styledEcho fgMagenta, styleBright, emoji["🐥"](), " Project language: ", programmingLanguagesDesc[
    programmingLanguages.find($projectData.language)
  ]
  styledEcho fgMagenta, styleBright, emoji["🔌"](), " Main file: ", fgWhite, projectData.mainFile
  styledEcho fgMagenta, styleBright, emoji["📁"](), " Source directory: ", fgWhite, projectData.srcDir
  styledEcho fgMagenta, styleBright, emoji["📁"](), " Assets directory: ", fgWhite, projectData.assetsDir
  styledEcho fgMagenta, styleBright, emoji["📁"](), " Build directory: ", fgWhite, projectData.buildDir

  # Writen code lines count? (only .py/.nim/.js/.ts)
  var bytes: BiggestInt = 0
  for file in walkDirRec("./"):
    case projectData.language
    of plNim:
      if file.endsWith(".exe") or file.endsWith(".js"):
        continue
    of plPython:
      if file.endsWith(".pyc"):
        continue
    else:
      discard
    try:
      bytes += file.getFileSize()
    except:
      discard
  
  echo ""
  styledEcho fgMagenta, styleBright, emoji["📦"](), " Project size: ", fgWhite, bytes.formatSize()

  var output = execProcess(
    "git rev-list --count master", getCurrentDir()
  ).strip()
  var commit: int

  if output.scanf("$i", commit):
    echo ""
    styledEcho fgBlue, styleBright, emoji["😸"](), " Git Story ", emoji["😸"]()
    styledEcho fgMagenta, styleBright, "🛠 Commit count: ", fgWhite, output
  
  output = execProcess(
    "git rev-parse HEAD", getCurrentDir()
  ).strip()

  if output.len == 40:
    styledEcho fgMagenta, styleBright, emoji["✨"](), " Latest commit: ", fgWhite, output

  QuitSuccess
