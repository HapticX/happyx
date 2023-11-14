## # Decorators 🔌
## 
## Provides convenient wrapper to create route decorators
## 
import
  macros,
  tables,
  base64


export base64


type
  DecoratorImpl* = proc(httpMethods: seq[string], routePath: string, statementList: NimNode)


var decorators* {.compileTime.} = newTable[string, DecoratorImpl]()


proc regDecorator*(decoratorName: string, decorator: DecoratorImpl) {.compileTime.} =
   decorators[decoratorName] = decorator


proc authBasicDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode) =
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


proc getUserAgentDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode) =
  statementList.insert(0, parseStmt"""
var userAgent = navigator.userAgent
"""
  )


static:
  regDecorator("AuthBasic", authBasicDecoratorImpl)
  regDecorator("GetUserAgent", getUserAgentDecoratorImpl)
