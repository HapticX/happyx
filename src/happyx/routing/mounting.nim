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
  ../core/[exceptions]

when not declared(CacheTable.hasKey):
  import ../private/macro_utils


const registeredMounts* = CacheTable"HappyXRegisteredMounts"


proc findAndReplaceMount*(body: NimNode) =
  ## ⚠ `Low-level API` ⚠
  ## 
  ## Don't use it in product
  ## 
  var offset =  0
  for i in 0..<body.len:
    let idx = i+offset
    if body[idx].kind == nnkCommand and body[idx][0] == ident"mount":
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

        for statement in mountBody:
          # Replace routes
          if statement.kind in [nnkCall, nnkCommand]:
            if statement[0].kind in [nnkStrLit, nnkTripleStrLit]:
              statement[0] = newLit($route & $statement[0])
            elif statement[1].kind in [nnkStrLit, nnkTripleStrLit]:
              statement[1] = newLit($route & $statement[1])
          # Add mount routes
          if (statement.kind in [nnkCall, nnkCommand] and $statement[0] != "mount") or
             (statement.kind == nnkPrefix and $statement[0] == "@"):
            inc offset
            body.insert(i, statement)


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
