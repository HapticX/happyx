## # Decorators 🔌
## 
## Provides convenient wrapper to create route decorators
## 
## > It can be used for plugins also
## 
## ## Decorator Usage Example ✨
## 
## 
## .. code-block:: nim
##    serve ...:
##      @AuthBasic
##      get "/":
##        # password and username takes from header "Authorization"
##        # Authorization: Bearer BASE64
##        echo username
##        echo password
## 
## 
## ## Own decorators
## 
## 
## .. code-block:: nim
##    proc myDecorator(httpMethods: seq[string], routePath: string, statementList: NimNode) =
##      statementList.insert(0, newCall("echo", newLit"My own decorator"))
##    # Register decorator
##    static:
##      regDecorator("MyDecorator", myDecorator)
##    # Use it
##    serve ...:
##      @MyDecorator
##      get "/":
## 
import
  std/macros,
  std/tables,
  std/strformat,
  std/base64,
  ../core/constants


export base64


type
  DecoratorImpl* = proc(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode])


var decorators* {.compileTime.} = newTable[string, DecoratorImpl]()


proc regDecorator*(decoratorName: string, decorator: DecoratorImpl) {.compileTime.} =
   decorators[decoratorName] = decorator


macro decorator*(name, body: untyped): untyped =
  let decoratorImpl = $name & "Impl"
  newStmtList(
    newProc(
      postfix(ident(decoratorImpl), "*"),
      [
        newEmptyNode(),
        newIdentDefs(ident"httpMethods", newNimNode(nnkBracketExpr).add(ident"seq", ident"string")),
        newIdentDefs(ident"routePath", ident"string"),
        newIdentDefs(ident"statementList", ident"NimNode"),
        newIdentDefs(ident"arguments", newNimNode(nnkBracketExpr).add(ident"seq", ident"NimNode")),
      ],
      body
    ),
    newNimNode(nnkStaticStmt).add(
      newCall("regDecorator", newLit($name), ident(decoratorImpl))
    )
  )


when enableDefaultDecorators:
  proc authBasicDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    statementList.insert(0, parseStmt"""
var (username, password) = ("", "")
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {"response": "failure", "reason": "You should to use Basic authorization!"}
else:
  (username, password) = block:
    let code = headers["Authorization"].split(" ")[1]
    let decoded = base64.decode(code).split(":", 1)
    (decoded[0], decoded[1])"""
    )
  

  proc authBearerJwtDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    let variableName = if arguments.len > 0: arguments[0] else: ident"jwtToken"
    statementList.insert(0, parseStmt(fmt"""
var {variableName}: TableRef[system.string, claims.Claim]
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {{"response": "failure", "reason": "You should to be authorized!"}}
else:
  if headers["Authorization"].startsWith("Bearer "):
    {variableName} = headers["Authorization"][7..^1].toJWT.claims
  else:
    var statusCode = 401
    return {{"response": "failure", "reason": "You should to be authorized!"}}""")
    )
  

  proc authJwtDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    let variableName = if arguments.len > 0: arguments[0] else: ident"jwtToken"
    statementList.insert(0, parseStmt(fmt"""
var {variableName}: TableRef[system.string, claims.Claim]
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {{"response": "failure", "reason": "You should to be authorized!"}}
else:
  {variableName} = headers["Authorization"].toJWT.claims""")
    )


  proc getUserAgentDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
    statementList.insert(0, parseStmt"""
var userAgent = navigator.userAgent
"""
    )


  static:
    regDecorator("AuthBasic", authBasicDecoratorImpl)
    regDecorator("AuthBearerJWT", authBearerJwtDecoratorImpl)
    regDecorator("AuthJWT", authJwtDecoratorImpl)
    regDecorator("GetUserAgent", getUserAgentDecoratorImpl)
