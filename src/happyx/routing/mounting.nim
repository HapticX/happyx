## # Mounting 🔌
## 
## Provides powerful and effective mounting ✨
## 
## ## Usage Example 🔨
## 
## .. code-block:: nim
##    mount Settings:
##      "/":
##        ...
##    mount Profile:
##      mount "/settings" -> Settings
##      mount "/config" -> Settings
## 
##    serve(...):  # or appRoutes
##      mount "/profile" -> Profile
## 
import
  # stdlib
  std/macros,
  std/macrocache,
  std/strformat,
  # HappyX
  ../core/[exceptions],
  ./decorators

when not declared(CacheTable.hasKey):
  import ../private/macro_utils


const registeredMounts* = CacheTable"HappyXRegisteredMounts"


proc findAndReplaceMount*(body: NimNode) =
  ## ⚠ `Low-level API` ⚠
  ## 
  ## Don't use it in product
  ## 
  var
    offset = 0
    nextRouteDecorators: seq[NimNode] = @[]
  for i in 0..<body.len:
    let idx = i+offset
    # Decorators
    if body[idx].kind == nnkPrefix and body[idx][0] == ident"@" and body[idx][1].kind == nnkIdent:
      # @Decorator
      nextRouteDecorators.add(body[idx].copy())
    # @Decorator()
    elif body[idx].kind == nnkCall and body[idx][0].kind == nnkPrefix and body[idx][0][0] == ident"@" and body[idx].len == 1:
      nextRouteDecorators.add(body[idx].copy())
    # @Decorator(arg1, arg2, ...)
    elif body[idx].kind == nnkCall and body[idx][0].kind == nnkPrefix and body[idx][0][0] == ident"@" and body[idx].len > 1:
      nextRouteDecorators.add(body[idx].copy())
    elif body[idx].kind == nnkCommand and body[idx][0] == ident"mount":
      if body[idx][1].kind == nnkInfix and body[idx][1][0] == ident"->":
        # handle mount
        let
          name = body[idx][1][2]
          route = body[idx][1][1]
        if not registeredMounts.hasKey($name):
          throwDefect(
            HpxMountDefect,
            fmt"Mount {name} is not declared",
            lineInfoObj(body[idx])
          )
        
        # Copy mount body and find and replace mount recursively
        var mountBody = copy(registeredMounts[$name])
        mountBody.findAndReplaceMount()

        var decoratorsOffset = 0

        for statement in mountBody:
          # Replace routes
          if statement.kind in [nnkCall, nnkCommand]:
            if statement[0].kind in [nnkStrLit, nnkTripleStrLit]:
              statement[0] = newLit($route & $statement[0])
            elif statement[1].kind in [nnkStrLit, nnkTripleStrLit]:
              statement[1] = newLit($route & $statement[1])
          # Add mount routes
          # @Decorator
          if statement.kind == nnkPrefix and statement[0] == ident"@":
            body.insert(i, statement)
            inc offset
            inc decoratorsOffset
          # @Decorator(....)
          elif statement.kind == nnkCall and statement[0].kind == nnkPrefix and statement[0][0] == ident"@":
            body.insert(i, statement)
            inc offset
            inc decoratorsOffset
          # get / post / etc.
          elif statement.kind in [nnkCall, nnkCommand] and statement[0] != ident"mount":
            # Add mount decorators
            for decorator in nextRouteDecorators:
              body.insert(i+decoratorsOffset, decorator)
              inc offset
            body.insert(i+decoratorsOffset, statement)
            inc offset
            decoratorsOffset = 0
        nextRouteDecorators = @[]
      # else:
      #   nextRouteDecorators = @[]


macro mount*(mountName, body: untyped): untyped =
  ## Registers new mount
  ## 
  ## ## Usage
  ## 
  ## .. code-block::nim
  ##    mount User:
  ##      get "/":
  ##        "Hello, from user"
  ## 
  ##    serve "127.0.0.1", 5000:
  ##      mount "/user" -> User
  ## 
  if mountName.kind != nnkIdent:
    throwDefect(
      HpxMountDefect,
      fmt"Mount names should be identifier, but got {mountName.kind} ",
      lineInfoObj(mountName)
    )
  if body.kind != nnkStmtList:
    throwDefect(
      HpxMountDefect,
      fmt"Mount body should be statement list, but got {body.kind}",
      lineInfoObj(body)
    )
  registeredMounts[$mountName] = body
