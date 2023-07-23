## # Template Engine 🎴
## 
## Provides templates render with nimja library
## 
## ## Usage ❔
## 
## .. code-block:: nim
##    templateFolder("/public/templates")
## 
##    proc renderIndex(name: string): string =
##      renderTemplate("index.html")
##    
##    serve "127.0.0.1", 5000:
##      get "/":
##        return renderIndex("Ethosa")
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
