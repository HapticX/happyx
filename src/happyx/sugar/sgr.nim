## # Sugar 🍎
## 
## > Provides syntax sugar macros
## 
## # `->` Macro
## 
## .. code-block::nim
##    "/home" -> any:
##      # at any HTTP method
##      return "Hello, world!"
## 
import
  # stdlib
  strformat,
  macros,
  macrocache,
  tables,
  # HappyX
  ../core/[exceptions]


const sugarRoutes* = CacheTable"HappyXSugarRoutes"


macro `->`*(route, at, body: untyped): untyped =
  ## Syntax sugar for routing
  ## 
  ## For SPA you can use:
  ## 
  ## .. code-block:: nim
  ##    "/route" -> build:
  ##      ...
  ## 
  ## For SSR you can use:
  ## 
  ## .. code-block:: nim
  ##    "/route" -> any:
  ##      ...
  ##    "/otherRoute" -> get:
  ##      ...
  runnableExamples:
    "/syntaxSugar" -> get:
      return "Hello, world"
  if route.kind in [nnkStrLit, nnkTripleStrLit]:
    sugarRoutes[$route] = newCall(at, body)
  else:
    throwDefect(
      HpxSyntaxSugarDefect,
      fmt"Invalid syntax sugar: ",
      lineInfoObj(route)
    )
