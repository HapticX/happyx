## Provides syntax sugar macros
import
  # stdlib
  strformat,
  macros,
  tables,
  # HappyX
  ../private/exceptions


var
  sugarRoutes* {. compileTime .} = newTable[string, tuple[httpMethod: string, body: NimNode]]()


macro `->`*(route, at, body: untyped): untyped =
  ## Syntax sugar for routing
  ## 
  ## For SPA you can use:
  ## 
  ## .. code-block:: nim
  ##    "/route" -> build:
  ##      ...
  ## 
  ## For SSG you can use:
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
    sugarRoutes[$route] = (httpMethod: $at, body: body)
  else:
    throwDefect(
      SyntaxSugarDefect,
      fmt"Invalid syntax sugar: ",
      lineInfoObj(route)
    )
