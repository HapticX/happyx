import
  ./utils


proc html2tagCommand*(output: string = "", toProc: bool = false, args: seq[string]): int =
  ## Converts HTML into `buildHtml` macro
  styledEcho fgGreen, emoji["🔨"](), " Convert HTML into happyx file"
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
    outputData =
      if toProc:
        "import happyx\n\n\nproc " & args[0].replace(re2"\-(\w|\d)", "_$1") & "*(): TagRef = buildHtml:"
      else:
        "import happyx\n\n\nvar html = buildHtml:\n"
  xmlTree2Text(outputData, tree, 2)

  outputData = outputData.replace(re2"""( +)(tScript.*?:)\s+(\"{3})\s*([\s\S]+?)(\"{3})""", "$1$2 $3\n  $1$4$1$5")

  file = open(o, fmWrite)
  file.write(outputData)
  file.close()
  styledEcho fgGreen, emoji["✅"](), " Successfully!"
  shutdownCli()
  QuitSuccess
