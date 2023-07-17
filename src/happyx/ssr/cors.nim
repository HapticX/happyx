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
  httpcore,
  strutils,
  strformat,
  # Happyx
  ../core/[exceptions]



type
  CORSObj* = object
    allowCredentials*: bool
    allowHeaders*: string
    allowOrigins*: string
    allowMethods*: string


var currentCORS {. compileTime .} = CORSObj()


macro addCORSHeaders*(headers: HttpHeaders) =
  let
    allowCredentials = currentCORS.allowCredentials
    allowHeaders= currentCORS.allowHeaders
    allowOrigins= currentCORS.allowOrigins
    allowMethods= currentCORS.allowMethods
  result = quote do:
    `headers`["Access-Control-Allow-Credentials"] = $`allowCredentials`
    if `allowHeaders`.len > 0:
      `headers`["Access-Control-Allow-Headers"] = `allowHeaders`
    if `allowMethods`.len > 0:
      `headers`["Access-Control-Allow-Methods"] = `allowMethods`
    if `allowOrigins`.len > 0:
      `headers`["Access-Control-Allow-Origin"] = `allowOrigins`


macro regCORS*(body: untyped): untyped =
  ## Register CORS
  for statement in body:
    if statement.kind == nnkCall and statement[1].kind == nnkStmtList:
      let
        name = statement[0]
        val = statement[1][0]
      case $name
      of "credentials":
        if val.kind == nnkIdent and $val in ["on", "off", "yes", "no", "true", "false"]:
          currentCORS.allowCredentials = parseBool($val)
          continue
      of "methods":
        if val.kind in [nnkStrLit, nnkTripleStrLit]:
          currentCORS.allowMethods = $val
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
          currentCORS.allowMethods = methods.join(",")
          continue
      of "headers":
        if val.kind in [nnkStrLit, nnkTripleStrLit]:
          currentCORS.allowHeaders = $val
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
          currentCORS.allowMethods = headers.join(",")
          continue
      of "origins":
        if val.kind in [nnkStrLit, nnkTripleStrLit]:
          currentCORS.allowOrigins = $val
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
          currentCORS.allowOrigins = origins.join(",")
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
