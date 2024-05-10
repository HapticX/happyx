import
  std/macros


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
