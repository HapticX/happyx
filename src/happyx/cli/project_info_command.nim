import
  ./utils


proc projectInfoCommand*(): int =
  if not isProject():
    styledEcho fgRed, "Current folder is not HappyX project. ❌"
    return QuitFailure
  var projectData = readConfig()
  styledEcho fgMagenta, styleBright, "🔥 Project name: ", fgGreen, projectData.name
  styledEcho fgMagenta, styleBright, "⚡ Project type: ", projectTypesDesc[
    projectTypes.find($projectData.projectType)
  ]
  styledEcho fgMagenta, styleBright, "🐥 Project language: ", programmingLanguagesDesc[
    programmingLanguages.find($projectData.language)
  ]
  styledEcho fgMagenta, styleBright, "🔌 Main file: ", fgWhite, projectData.mainFile
  styledEcho fgMagenta, styleBright, "📁 Source directory: ", fgWhite, projectData.srcDir
  styledEcho fgMagenta, styleBright, "📁 Assets directory: ", fgWhite, projectData.assetsDir
  styledEcho fgMagenta, styleBright, "📁 Build directory: ", fgWhite, projectData.buildDir

  # Writen code lines count? (only .py/.nim/.js/.ts)
  var bytes = 0
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
  styledEcho fgMagenta, styleBright, "📦 Project size: ", fgWhite, bytes.formatSize()

  var output = execProcess(
    "git rev-list --count master", getCurrentDir()
  ).replace(re2"^\s*", "").replace(re2"\s*$", "")

  if output.match(re2"^\d+$"):
    echo ""
    styledEcho fgBlue, styleBright, "😸 Git Story 😸"
    styledEcho fgMagenta, styleBright, "🛠 Commit count: ", fgWhite, output
  
  output = execProcess(
    "git rev-parse HEAD", getCurrentDir()
  ).replace(re2"^\s*", "").replace(re2"\s*$", "")

  if output.len == 40 and output.match(re2"^[\S]+$"):
    styledEcho fgMagenta, styleBright, "✨ Latest commit: ", fgWhite, output

  QuitSuccess
