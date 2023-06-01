## # Template Engine 🎴
## 
## Provides templates render with nimja library
## 

import
  nimja,
  os

export
  nimja


var templatesFolder* {.compileTime.} = getScriptDir()


proc templateFolder*(f: static[string]) =
  ## Specifies templates folder
  static:
    templatesFolder = templatesFolder / f


template renderTemplate*(name: static[string]) =
  ## Renders template from file
  compileTemplateFile(templatesFolder / name)
