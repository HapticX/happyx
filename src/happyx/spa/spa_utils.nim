import
  std/macros,
  std/strutils,
  std/jsffi

export jsffi


proc await*(x: JsObject): JsObject {.discardable, importjs: "(await #)".}
proc clearTimeout*(x: JsObject): JsObject {.discardable, importjs: "clearTimeout(#)".}
proc clearInterval*(x: JsObject): JsObject {.discardable, importjs: "clearInterval(#)".}


macro eventListener*(obj: untyped, event: string, body: untyped): untyped =
  newStmtList(
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & $obj & "`.addEventListener('" & $event & "', (event) => {")
      )
    ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("});")
      )
    ),
  )


macro withVariables*(variables: varargs[untyped]): untyped =
  var names: seq[string] = @[]
  for i in variables[0..^2]:
    names.add("`" & $i & "`")
  newStmtList(
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("const __withVariables = (" & names.join(",") & ") => {")
      )
    ),
    variables[^1],
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("};\n__withVariables(" & names.join(",") & ");")
      )
    ),
  )


macro withTimeout*(time: int, id, body: untyped): untyped =
  newStmtList(
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident"__timeoutTime", ident"cint", time)
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("let " & $id & " = setTimeout(() => {")
      )
    ),
    newNimNode(nnkVarSection).add(
      newIdentDefs(id, ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & $id & "` = " & $id & ";")
      )
    ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("}, `__timeoutTime`);")
      )
    ),
  )


macro js*(obj: untyped): untyped =
  newStmtList(
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident"__o", ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`__o` = " & $obj.toStrLit & ";")
      )
    ),
    ident"__o"
  )


macro withInterval*(time: static[int], ident, body: untyped): untyped =
  newStmtList(
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("let " & $ident & " = setInterval(() => {")
      )
    ),
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident, ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & $ident & "` = " & $ident & ";")
      )
    ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("}," & $time & ");")
      )
    ),
  )


macro withPromise*(ident, body: untyped): untyped =
  newStmtList(
    newNimNode(nnkVarSection).add(
      newIdentDefs(
        ident"__promise",
        ident"JsObject",
        newEmptyNode()
      )
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`__promise` = new Promise(" & $ident & " => {")
      )
    ),
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident, ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & $ident & "` = " & $ident & ";")
      )
    ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("});")
      )
    ),
    ident"__promise"
  )
