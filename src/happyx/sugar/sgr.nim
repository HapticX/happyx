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
  std/strformat,
  std/macros,
  std/macrocache,
  std/enumutils,
  std/typetraits,
  std/sequtils,
  std/strutils,
  # HappyX
  ../core/[exceptions]


const sugarRoutes* = CacheTable"HappyXSugarRoutes"


template `:=`*(name, value: untyped): untyped =
  (var name = value; name)


proc has*[T: HoleyEnum, U](e: typedesc[T], val: U): bool =
  when val is e:
    return val in e.toSeq
  elif val is string:
    try:
      discard parseEnum[e](val)
      return true
    except ValueError:
      return false
  else:
    return false


proc has*[T: OrdinalEnum, U](e: typedesc[T], val: U): bool =
  when val is e:
    return val in e.low..e.high
  elif val is string:
    try:
      discard parseEnum[e](val)
      return true
    except ValueError:
      return false
  else:
    return false


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
