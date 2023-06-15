import
  regex,
  strutils,
  macros


let discardStmt* {. compileTime .} = newNimNode(nnkDiscardStmt).add(newEmptyNode())


{. push compileTime .}

proc getTagName*(name: string): string =
  ## Checks tag name at compile time
  ## 
  ## tagDiv, tDiv, hDiv -> div
  if re"^tag[A-Z]" in name:
    name[3..^1].toLower()
  elif re"^[ht][A-Z]" in name:
    name[1..^1].toLower()
  else:
    name


proc newMultiVarStmt*(extractNames: openArray[NimNode], val: NimNode, isLet: bool = false): NimNode =
  result = newNimNode(
    if isLet: nnkLetSection else: nnkVarSection
  ).add(newNimNode(nnkVarTuple))
  for i in extractNames:
    result[0].add(i)
  result[0].add(newEmptyNode())
  result[0].add(val)


proc isExpr*(node: NimNode): bool =
  if node.kind == nnkStmtList and node.len > 0:
    return node[^1].isExpr
  if node.kind in AtomicNodes:
    return true
  if node.kind in nnkCallKinds:
    if node[0].kind == nnkIdent:
      let fnName = $node[0]
      if re"^(answer|echo|styledEcho|styledWrite|write|await)" in fnName.toLower():
        return false
      return true
  if node.kind in [nnkIfExpr, nnkIfStmt]:
    for child in node.children:
      if child.kind notin [nnkElse, nnkElseExpr] and not child[^1].isExpr:
        return false
    return true
  if node.kind == nnkCaseStmt:
    var i = 0
    for child in node.children:
      if i == 0:
        inc i
        continue
      if child.kind notin [nnkElse, nnkElseExpr] and not child[^1].isExpr:
        return false
      inc i
    return true
  false


proc isIdentUsed*(body, name: NimNode): bool =
  ## Finds usage ident `name` in `body`
  for statement in body:
    if statement.kind == nnkIdent and $statement == $name:
      return true
    elif statement.kind notin AtomicNodes and statement.isIdentUsed(name):
      return true
  false


proc newLambda*(body: NimNode, params: seq[NimNode] | NimNode = @[newEmptyNode()],
                pragmas: seq[NimNode] | seq[string] = @[newEmptyNode()]): NimNode =
  ## Creates a new lambda
  # Params
  when params is seq[NimNode]:
    let formalParams = newNimNode(nnkFormalParams)

    for param in params:
      formalParams.add(param)
  else:
    let formalParams = params
  
  # Pragmas
  when pragmas is seq[NimNode]:
    let pragma = newNimNode(nnkPragma)

    for i in pragmas:
      if i.kind != nnkEmpty:
        pragma.add(i)
  elif pragmas is seq[string]:
    let pragma = newNimNode(nnkPragma)

    for i in pragmas:
      if i.len != 0:
        pragma.add(ident(i))

  newNimNode(nnkLambda).add(
    newEmptyNode(),  # name
    newEmptyNode(),  # for templates and macros
    newEmptyNode(),  # generics
    formalParams,
    if pragma.len == 0: newEmptyNode() else: pragma,
    newEmptyNode(),  # reserved slot for future use
    body
  )
