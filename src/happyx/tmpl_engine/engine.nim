import
  nimja,
  os

export
  nimja


var
  templatesFolder* {.compileTime.} = getScriptDir()


proc templateFolder*(f: static[string]) =
  static:
    templatesFolder = templatesFolder / f


template renderTemplate*(name: static[string]) =
  compileTemplateFile(templatesFolder / name)
