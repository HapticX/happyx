## Provides effective mounting ✨
import
  # stdlib
  macros,
  tables,
  strformat,
  # HappyX
  ../private/exceptions


var registeredMounts* {. compileTime .} = newTable[string, NimNode]()


proc findAndReplaceMount*(body: NimNode) {. compileTime .} =
  # Find mounts
  var offset =  0
  for i in 0..<body.len:
    let idx = i+offset
    if body[idx].kind == nnkCommand and $body[idx][0] == "mount":
      if body[idx][1].kind == nnkInfix and $body[idx][1][0] == "->":
        # handle mount
        let
          name = body[idx][1][2]
          route = body[idx][1][1]
        if not registeredMounts.hasKey($name):
          throwDefect(
            MountDefect,
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
              statement[0] = newStrLitNode($route & $statement[0])
            elif statement[1].kind in [nnkStrLit, nnkTripleStrLit]:
              statement[1] = newStrLitNode($route & $statement[1])
          # Add mount routes
          if statement.kind != nnkCommand and $statement[0] != "mount":
            inc offset
            body.insert(i, statement)


macro mount*(mountName, body: untyped): untyped =
  ## Registers new mount
  assert mountName.kind == nnkIdent
  assert body.kind == nnkStmtList
  registeredMounts[$mountName] = body
