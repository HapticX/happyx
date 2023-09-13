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
  macros,
  macrocache,
  os,
  ../private/macro_utils

export
  nimja


const templatesFolder = CacheTable"HappyXTemplateFolder"


macro templateFolder*(f: string) =
  ## Specifies templates folder
  templatesFolder["f"] = f


macro renderTemplate*(name: static[string]): untyped =
  ## Renders template from file
  let folder = getScriptDir() / $templatesFolder["f"] / name
  newCall("compileTemplateFile", newLit(folder))
