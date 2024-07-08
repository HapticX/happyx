import
  ./utils,
  std/parsecsv


proc translateCsvCommand*(filename: string, output: string): int =
  let o = if output == "": filename.split(".")[0] & ".nim" else: output

  var
    f: File
    p: CsvParser
    translated = "import happyx\n\ntranslatables:\n"

  p.open(filename)
  p.readHeaderRow()
  while p.readRow():
    var row = ""
    for h in p.headers:
      echo p.headers, ", ", p.row
      if h.toLower() == "id":
        row &= "  \"" & p.rowEntry(h) & "\":\n"
      else:
        row &= "    \"" & h.toLower() & "\" -> \"" & p.rowEntry(h) & "\"\n"
    translated &= row

  f = open(o, fmWrite)
  f.write(translated)
  f.close()

  QuitSuccess
