import
  ./utils


proc buildCommand*(optSize: bool = false): int =
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