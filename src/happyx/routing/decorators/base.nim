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
  std/strutils,
  std/base64,
  ../../core/constants,
  ../../private/macro_utils,
  ../routing


export base64


type
  DecoratorImpl* = proc(
    httpMethods: seq[string],
    routePath: string,
    statementList: NimNode,
    arguments: seq[NimNode]
  )


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
