## Provides working with Cross-Origin Resource Sharing (CORS) ✨
## 
## ## Example
## 
## .. code-block::nim
##    regCORS:
##      origins: ["https://google.com", "http://localhost:5000"]
##      methods: ["GET", "POST"]
##      headers: ["*"]
##      credentials: true
## 
import
  # stdlib
  macros,
  macrocache,
  httpcore,
  strutils,
  strformat,
  # Happyx
  ../core/[exceptions]



type
  CORSObj* = object
    allowCredentials*: bool
    allowHeaders*: string
    allowOrigins*: seq[string]
    allowMethods*: string


var currentCORSRuntime* = CORSObj()

proc setCors*(allowOrigins: string = "*", allowMethods: string = "*",
              allowHeaders: string = "*", credentials: bool = true) {.gcsafe.} =
  {.cast(gcsafe).}:
    currentCORSRuntime.allowCredentials = credentials
    currentCORSRuntime.allowOrigins = @[allowOrigins]
    currentCORSRuntime.allowMethods = allowMethods
    currentCORSRuntime.allowHeaders = allowHeaders

proc getCors*(): CORSObj {.gcsafe.} =
  {.gcsafe.}:
    return currentCORSRuntime


macro addCORSHeaders*(host: string, headers: HttpHeaders) =
  result = quote do:
    let cors = getCors()
    `headers`["Access-Control-Allow-Credentials"] = $cors.allowCredentials
    if cors.allowHeaders.len > 0:
      `headers`["Access-Control-Allow-Headers"] = cors.allowHeaders
    if cors.allowMethods.len > 0:
      `headers`["Access-Control-Allow-Methods"] = cors.allowMethods
    if cors.allowOrigins.len > 0:
      for origin in cors.allowOrigins:
        if origin == "*":
          `headers`["Access-Control-Allow-Origin"] = "*"
          break
        elif origin == `host`:
          `headers`["Access-Control-Allow-Origin"] = origin
          break
      if not `headers`.hasKey("Access-Control-Allow-Origin"):
        `headers`["Access-Control-Allow-Origin"] = cors.allowOrigins[0]


macro regCORS*(body: untyped): untyped =
  ## Register CORS
  result = newCall("setCors")
  for statement in body:
    if statement.kind == nnkCall and statement[1].kind == nnkStmtList:
      let
        name = statement[0]
        val = statement[1][0]
      case $name
      of "credentials":
        if val.kind == nnkIdent and $val in ["on", "off", "yes", "no", "true", "false"]:
          result.add(newNimNode(nnkExprEqExpr).add(ident"credentials", newLit(parseBool($val))))
          continue
      of "methods":
        if val.kind in [nnkStrLit, nnkTripleStrLit]:
          result.add(newNimNode(nnkExprEqExpr).add(ident"allowMethods", newLit($val)))
          continue
        elif val.kind == nnkBracket:
          var methods: seq[string] = @[]
          for i in val.children:
            if i.kind in [nnkStrLit, nnkTripleStrLit]:
              methods.add($i)
            else:
              throwDefect(
                HpxCorsDefect,
                fmt"invalid regCORS methods syntax: ",
                lineInfoObj(val)
              )
          result.add(newNimNode(nnkExprEqExpr).add(ident"allowMethods", newLit(methods.join(","))))
          continue
      of "headers":
        if val.kind in [nnkStrLit, nnkTripleStrLit]:
          result.add(newNimNode(nnkExprEqExpr).add(ident"allowHeaders", newLit($val)))
          continue
        elif val.kind == nnkBracket:
          var headers: seq[string] = @[]
          for i in val.children:
            if i.kind in [nnkStrLit, nnkTripleStrLit]:
              headers.add($i)
            else:
              throwDefect(
                HpxCorsDefect,
                fmt"invalid regCORS headers syntax: ",
                lineInfoObj(val)
              )
          result.add(newNimNode(nnkExprEqExpr).add(ident"allowHeaders", newLit(headers.join(","))))
          continue
      of "origins":
        if val.kind in [nnkStrLit, nnkTripleStrLit]:
          result.add(newNimNode(nnkExprEqExpr).add(ident"allowOrigins", newLit($val)))
          continue
        elif val.kind == nnkBracket:
          var origins: seq[string] = @[]
          for i in val.children:
            if i.kind in [nnkStrLit, nnkTripleStrLit]:
              origins.add($i)
            else:
              throwDefect(
                HpxCorsDefect,
                fmt"invalid regCORS origins syntax: ",
                lineInfoObj(val)
              )
          result.add(newNimNode(nnkExprEqExpr).add(ident"allowOrigins", newLit(origins.join(","))))
          continue
      else:
        throwDefect(
          HpxCorsDefect,
          fmt"invalid regCORS statement syntax: ",
          lineInfoObj(statement)
        )
          
    throwDefect(
      HpxCorsDefect,
      fmt"invalid regCORS syntax: ",
      lineInfoObj(statement)
    )
