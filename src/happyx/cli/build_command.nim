import
  ./utils


proc buildCommand*(optSize: bool = false, no_compile: bool = false): int =
  ## Builds Single page application project into one HTML and JS files
  styledEcho emoji["🔥"](), " Welcome to ", styleBright, fgMagenta, "HappyX ", resetStyle, fgWhite, "builder"
  let project = if not no_compile: compileProject() else: readConfig()
  let assetsDir = project.assetsDir.replace("\\", "/").replace('/', DirSep)
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
    minified = minifyJs(data)
    size = data.len.int64
    sizeNew = minified.len.int64
  f.close()
  f = open(project.buildDir / fmt"{SPA_MAIN_FILE}.js", fmWrite)
  f.write(minified)
  f.close()
  eraseLine()
  cursorUp()
  styledEcho fgGreen, "✅ Build completed"
  styledEcho(
    fgGreen, "Compressed from ",
    size.formatSize('.', bpColloquial, true), " to ",
    sizeNew.formatSize('.', bpColloquial, true)
  )
  shutdownCli()
  QuitSuccess
