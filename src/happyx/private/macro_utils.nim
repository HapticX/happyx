## # Macro Utils
## 
## ## ⚠ Warning: This Module Is LOW-LEVEL API ⚠
## 
import
  std/strutils,
  std/strformat,
  std/macros,
  std/macrocache,
  ../core/[exceptions, constants]


# Compile time variables
const
  uniqueId* = CacheCounter"uniqueId"
  slots* = CacheSeq"hpxSlots"
  createdComponents = CacheTable"HappyXCreatedComponents"
  UniqueComponentId* = "uniqCompId"


proc discardStmt*: NimNode = newNimNode(nnkDiscardStmt).add(newEmptyNode())


when not declared(macrocache.hasKey):
  proc hasKey*(self: CacheTable, key: string): bool =
    for k, v in self.pairs():
      if k == key:
        return true
    return false
  
when not declared(macrocache.contains):
  proc contains*(self: CacheTable, key: string): bool = hasKey(self, key)


proc buildHtmlProcedure*(root, body: NimNode, inComponent: bool = false,
                         componentName: NimNode = newEmptyNode(), inCycle: bool = false,
                         cycleTmpVar: string = "", compTmpVar: NimNode = newEmptyNode(),
                         cycleVars: var seq[NimNode], parent: NimNode = newEmptyNode()): NimNode


proc bracket*(node: varargs[NimNode]): NimNode =
  result = newNimNode(nnkBracket)
  for i in node:
    result.add(i)


proc isIdentUsed*(body, name: NimNode): bool =
  ## Finds usage ident `name` in `body`
  for statement in body:
    if body.kind in {nnkIdentDefs, nnkExprEqExpr, nnkExprColonExpr} and statement == body[0]:
      continue
    if body.kind == nnkDotExpr and statement == body[1] and statement != body[0]:
      continue
    if statement == name:
      return true
    elif statement.kind notin AtomicNodes and statement.isIdentUsed(name):
      return true
    elif statement.kind in {nnkStrLit, nnkTripleStrLit, nnkRStrLit} and $name in $statement:
      return true
  false


proc newCast*(fromType, toType: NimNode): NimNode =
  newNimNode(nnkCast).add(toType, fromType)


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


proc bracket*(node: seq[NimNode] | seq[string]): NimNode =
  when node is seq[NimNode]:
    result = newNimNode(nnkBracket)
    for i in node:
      result.add(i)
  else:
    result = newNimNode(nnkBracket)
    for i in node:
      result.add(newLit(i))


proc pragmaBlock*(pragmas: openArray[NimNode], statementList: NimNode): NimNode =
  result = newNimNode(nnkPragmaBlock).add(
    newNimNode(nnkPragma),
    statementList
  )
  for i in pragmas:
    result[0].add(i)


proc getTagName*(name: string): string =
  ## Checks tag name at compile time
  ## 
  ## tagDiv, tDiv, hDiv -> div
  if name.len > 3 and name.startsWith("tag") and name[3].isAlphaAscii():
    name[3..^1].toLower()
  elif name.len > 1 and name[0] in {'h', 't'} and name[1].isAlphaAscii():
    name[1..^1].toLower()
  else:
    name


proc formatNode*(node: NimNode): NimNode =
  if node.kind == nnkStrLit and "{" in $node and "}" in $node:
    newCall("fmt", node)
  else:
    node


proc useComponent*(statement: NimNode, inCycle, inComponent: bool,
                   cycleTmpVar: string, compTmpVar: NimNode, cycleVars: var seq[NimNode],
                   returnTagRef: bool = true, constructor: bool = false,
                   nameIsIdent: bool = false): NimNode =
  var
    name =
      if statement[1].kind == nnkCall:
        if statement[1][0].kind in AtomicNodes:
          statement[1][0]
        elif statement[1][0].kind == nnkBracketExpr:
          statement[1][0][0]
        else:
          statement[1][0][0]
      elif statement[1].kind == nnkInfix:
        statement[1][1]
      else:
        statement[1]
    generics =
      if statement[1].kind == nnkCall and statement[1][0].kind == nnkBracketExpr:
        statement[1][0]
      else:
        newEmptyNode()
    hasGenerics = generics.kind != nnkEmpty
    componentName = fmt"comp{uniqueId.value}{uniqueId.value + 2}{uniqueId.value * 2}{uniqueId.value + 7}"
    componentNameIdent =
      if cycleTmpVar == "" and compTmpVar.kind == nnkEmpty:
        newLit(componentName)
      elif compTmpVar.kind == nnkEmpty and cycleTmpVar != "":
        newCall("&", newLit(componentName), newCall("&", newLit"__", newCall("$", ident(cycleTmpVar))))
      elif cycleTmpVar == "" and compTmpVar.kind != nnkEmpty:
        newCall("&", newLit(componentName), newCall("$", compTmpVar))
      else:
        newCall("&", newLit(componentName), newCall("&", newCall("$", compTmpVar), newCall("&", newLit"__", newCall("$", ident(cycleTmpVar)))))
    componentSlotIdent = newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
      newCall("declared", ident"cycleCounter"),
      newCall("&", componentNameIdent, newCall("&", newLit"____", newCall("$", ident"cycleCounter")))
    ), newNimNode(nnkElse).add(
      componentNameIdent
    ))
    objConstr =
      if hasGenerics:
        var x = generics.copy()
        x[0] = 
          if constructor:
            ident(fmt"constructor_{name}")
          else:
            ident(fmt"init{name.toStrLit}")
        newCall(x)
      else:
        if constructor:
          newCall(fmt"constructor_{name}")
        else:
          newCall(fmt"init{name.toStrLit}")
    componentNameTmp = "_" & componentName
    componentData = "data_" & componentName
    stringId =
      when defined(js) or not enableLiveviews:
        if inCycle or inComponent:
          componentSlotIdent
        else:
          newLit(componentName)
      else:
        if inCycle or inComponent:
          newCall("&", ident"hostname", componentSlotIdent)
        else:
          newCall("&", ident"hostname", newLit(componentName))
    componentSlot =
      if statement.len > 1 and statement[^1].kind == nnkStmtList:
        statement[^1]
      elif statement.kind == nnkCommand and statement[0] == ident"component" and statement[1].kind == nnkCall and statement[1][^1].kind == nnkStmtList and createdComponents.hasKey($name):
        statement[1][^1]
      else:
        newStmtList(newNimNode(nnkDiscardStmt).add(newEmptyNode()))
  inc uniqueId
  objConstr.add(stringId)
  if statement[1].kind == nnkCall:
    for i in 1..<statement[1].len:
      # call -> arg
      if statement[1][i].kind != nnkStmtList:
        objConstr.add(statement[1][i])
  # Constructor
  elif statement[1].kind == nnkInfix and statement[1][0] == ident"->":
    for i in 1..<statement[1][2].len:
      # infix -> call -> arg
      objConstr.add(statement[1][2][i])
  result =
    newStmtList(
      newVarStmt(ident(componentNameTmp), objConstr),
      newVarStmt(
        ident(componentName),
        if hasGenerics:
          newCast(
            newCall("registerComponent", stringId, ident(componentNameTmp)),
            generics
          )
        else:
          newCall(
            name,
            newCall("registerComponent", stringId, ident(componentNameTmp))
          )
      ),
      newAssignment(
        newDotExpr(ident(componentName), ident"slot"),
        newLambda(
          newStmtList(
            if componentSlot.isIdentUsed(ident"scopeSelf"):
              if hasGenerics:
                newVarStmt(ident"scopeSelf", newCast(ident"scopeSelf", generics))
              else:
                newVarStmt(ident"scopeSelf", newDotExpr(ident"scopeSelf", name))
            else:
              newEmptyNode(),
            newLetStmt(
              ident"_res",
              newNimNode(nnkIfExpr).add(
                newNimNode(nnkElifBranch).add(
                  newCall("and", ident"inCycle", ident"inComponent"),
                  newCall("buildHtmlSlot", componentSlot, newLit(true), newLit(true))
                ),
                newNimNode(nnkElifBranch).add(
                  ident"inCycle",
                  newCall("buildHtmlSlot", componentSlot, newLit(true), newLit(false))
                ),
                newNimNode(nnkElifBranch).add(
                  ident"inComponent",
                  newCall("buildHtmlSlot", componentSlot, newLit(false), newLit(true))
                ),
                newNimNode(nnkElse).add(
                  newCall("buildHtmlSlot", componentSlot, newLit(false), newLit(false))
                )
              ),
              # buildHtmlProcedure(
              #   ident"div", componentSlot, inComponent, ident(componentName),
              #   inCycle, "cycleCounter", ident"compCounter", cycleVars
              # ).add(newNimNode(nnkExprEqExpr).add(ident"onlyChildren", newLit(true))),
            ),
            newAssignment(
              newDotExpr(ident(componentName), ident"slotData"),
              ident"_res"
            ),
            ident"_res"
          ), @[
            ident"TagRef",
            newIdentDefs(ident"scopeSelf", ident"BaseComponent"),
            newIdentDefs(ident"inComponent", ident"bool"),
            newIdentDefs(ident"compName", ident"string"),
            newIdentDefs(ident"inCycle", ident"bool"),
            newIdentDefs(ident"cycleCounter", newNimNode(nnkVarTy).add(ident"int")),
            newIdentDefs(ident"compCounter", ident"string"),
          ]
        )
      ),
      if returnTagRef:
        newLetStmt(
          ident(componentData),
          newCall("render", ident(componentName))
        )
      else:
        newEmptyNode(),
      if returnTagRef:
        newCall(
          "addArgIter",
          ident(componentData),
          newCall("&", newLit"data-", newDotExpr(ident(componentName), ident(UniqueComponentId)))
        )
      else:
        newEmptyNode(),
      when defined(js):
        if returnTagRef:
          newStmtList(
            newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
              ident"emit",
              newLit(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
            )),
            newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
              ident"emit",
              newLit(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
            )),
            newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
              ident"emit",
              newLit(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
            )),
          )
        else:
          newEmptyNode()
      else:
        newEmptyNode(),
      if returnTagRef:
        ident(componentData)
      else:
        ident(componentName)
  )
  when enableUseCompDebugMacro:
    echo result.toStrLit


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
      if "answer" in fnName:
        return false
      if "echo" in fnName:
        return false
      if "styledEcho" in fnName:
        return false
      if "styledWrite" in fnName:
        return false
      if "write" in fnName:
        return false
      if "await" in fnName:
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


proc replaceUseInComponent*(body: NimNode) =
  for statement in body:
    if statement.kind in nnkCallKinds and statement[0] == ident"use" and statement.len == 2:
      statement.add(newLit(true))
      statement.add(ident"uniqCompId")
    elif statement.kind notin AtomicNodes:
      statement.replaceUseInComponent()


proc replaceIter*(
    root: NimNode,
    search: proc(x: NimNode): bool,
    replace: proc(x: NimNode): NimNode
): bool =
  result = false
  for i in 0..root.len-1:
    result = root[i].replaceIter(search, replace)
    if search(root[i]):
      root[i] = replace(root[i])
      result = true


proc attribute*(attr: NimNode, inComponent: bool = false): NimNode =
  ## Converts `nnkExprEqExpr` to `nnkColonExpr`
  if attr.kind in AtomicNodes:
    newColonExpr(newLit"_", formatNode(attr))
  else:
    var
      k =
        if attr[0].kind in [nnkStrLit, nnkTripleStrLit]:
          $attr[0]
        else:
          $attr[0].toStrLit
      v =
        if k.toLower() == "id" and attr[1].kind in {nnkStrLit, nnkTripleStrLit} and inComponent:
          newLit($attr[1] & "{self.uniqCompId}")
        elif k.toLower() == "id" and attr[1].kind in CallNodes and attr[1][0] == ident"nu" and inComponent:
          newLit($attr[1][1])
        elif k.toLower() == "id" and attr[1].kind in CallNodes and attr[1][0] == ident"fmtnu" and inComponent:
          newCall("fmt", newLit($attr[1][1]))
        elif k.toLower() == "id" and attr[1].kind in CallNodes and attr[1][0] == ident"fmt" and inComponent:
          newCall("fmt", newLit($attr[1][1] & "{self.uniqCompId}"))
        else:
          attr[1]
    newColonExpr(
      newLit(k),
      formatNode(v)
    )


proc addAttribute*(node, key, value: NimNode, inComponent: bool = false) =
  var
    k = 
      if key.kind in [nnkStrLit, nnkTripleStrLit]:
        $key
      else:
        $key.toStrLit
    v =
      if k.toLower() == "id" and value.kind in {nnkStrLit, nnkTripleStrLit} and inComponent:
        formatNode(newLit($value & "{self.uniqCompId}"))
      elif k.toLower() == "id" and value.kind in CallNodes and value[0] == ident"nu" and inComponent:
        formatNode(newLit($value[1]))
      elif k.toLower() == "id" and value.kind in CallNodes and value[0] == ident"fmtnu" and inComponent:
        formatNode(newLit($value[1]))
      elif k.toLower() == "id" and value.kind in CallNodes and value[0] == ident"fmt" and inComponent:
        formatNode(newLit($value[1] & "{self.uniqCompId}"))
      else:
        value
  if node.kind == nnkCall:
    if node.len == 2:
      node.add(newCall("newStringTable", newNimNode(nnkTableConstr).add(
        newColonExpr(newLit(k), v)
      )))
    elif node[2].kind == nnkCall and node[2][0] == ident"newStringTable":
      node[2][1].add(newColonExpr(newLit(k), v))
    else:
      node.insert(2, newCall("newStringTable", newNimNode(nnkTableConstr).add(
        newColonExpr(newLit(k), v)
      )))
  elif node.kind == nnkStmtList and node[0].kind == nnkVarSection:
    let n = node[0][0][2]
    if n.len == 2:
      n.add(newCall("newStringTable", newNimNode(nnkTableConstr).add(
        newColonExpr(newLit(k), v)
      )))
    elif n[2].kind == nnkCall and n[2][0] == ident"newStringTable":
      n[2][1].add(newColonExpr(newLit(k), v))
    else:
      n.insert(2, newCall("newStringTable", newNimNode(nnkTableConstr).add(
        newColonExpr(newLit(k), v)
      )))


proc endsWithBuildHtml*(statement: NimNode): bool =
  statement[^1].kind == nnkCall and statement[^1][0] == ident"buildHtml"


proc replaceSelfComponent*(statement, componentName: NimNode, parent: NimNode = nil,
                           convert: bool = false, is_constructor: bool = false,
                           is_field: bool = true): NimNode {.discardable.} =
  let self = if convert: ident"self" else: newDotExpr(ident"self", componentName)
  result = newEmptyNode()
  if statement.kind == nnkDotExpr:
    if statement[0] == ident"self":
      if not parent.isNil() and parent.kind == nnkCall and parent[0] == statement:
        # Call field
        parent[0] = newCall(newDotExpr(newDotExpr(self, statement[1]), ident"val"))
      elif not parent.isNil() and parent.kind == nnkExprEqExpr:
        parent[1] = newDotExpr(
          newDotExpr(self, statement[1]), ident"val"
        )
        statement[0] = self
      else:
        statement[0] = self
    return

  if statement.kind == nnkAsgn:
    if statement[0].kind == nnkDotExpr and statement[0][0] == ident"self":
      statement[0] = newDotExpr(statement[0], ident"val")
      statement[0][0][0] = self
    var idxes: seq[tuple[node: NimNode, idx: int]] = @[]
    for idx, i in statement.pairs:
      if i.kind == nnkCall and i[0].kind == nnkDotExpr and i[0][0] == ident"self":
        idxes.add((i, idx))
      else:
        let r = i.replaceSelfComponent(componentName, statement, convert, is_constructor)
        if result.kind == nnkEmpty:
          result = r
    for (i, idx) in idxes:
      var
        methodCall = newCall(newDotExpr(self, i[0][1]))
        fieldCall = newCall(newCall(newDotExpr(newDotExpr(self, i[0][1]), ident"val")))
      for arg_idx, arg in i.pairs:
        if arg_idx == 0:
          continue
        fieldCall.add(arg)
        methodCall.add(arg)
      statement[idx] = newNimNode(nnkWhenStmt).add(
        newNimNode(nnkElifBranch).add(
          newCall("is", newCall("typeof", newDotExpr(self, i[0][1])), ident"State"),
          fieldCall
        ), newNimNode(nnkElse).add(
          methodCall
        )
      )
  else:
    for idx, i in statement.pairs:
      if i.kind == nnkAsgn and i[0].kind == nnkDotExpr and i[0][0] == ident"self":
        if not is_constructor:
          result = statement
    var idxes: seq[tuple[node: NimNode, idx: int]] = @[]
    for idx, i in statement.pairs:
      if i.kind == nnkCall and i[0].kind == nnkDotExpr and i[0][0] == ident"self":
        idxes.add((i, idx))
      else:
        let r = i.replaceSelfComponent(componentName, statement, convert, is_constructor)
        if result.kind == nnkEmpty:
          result = r
    for (i, idx) in idxes:
      var
        methodCall = newCall(newDotExpr(self, i[0][1]))
        fieldCall = newCall(newDotExpr(newDotExpr(self, i[0][1]), ident"val"))
      for arg_idx, arg in i.pairs:
        if arg_idx == 0:
          continue
        fieldCall.add(arg)
        methodCall.add(arg)
      statement[idx] = newNimNode(nnkWhenStmt).add(
        newNimNode(nnkElifBranch).add(
          newCall("is", newCall("typeof", newDotExpr(self, i[0][1])), ident"State"),
          fieldCall
        ), newNimNode(nnkElse).add(
          methodCall
        )
      )


proc buildHtmlProcedure*(root, body: NimNode, inComponent: bool = false,
                         componentName: NimNode = newEmptyNode(), inCycle: bool = false,
                         cycleTmpVar: string = "", compTmpVar: NimNode = newEmptyNode(),
                         cycleVars: var seq[NimNode], parent: NimNode = newEmptyNode()): NimNode =
  ## Builds HTML
  ## 
  ## Here you can use components and event handlers
  let elementName = newLit(getTagName($root))
  var events = newStmtList()
  var elemEventId = uniqueId.value
  result = newCall("initTag", elementName)

  for statement in body:
    if statement.kind == nnkDiscardStmt:
      continue
    elif statement.kind == nnkPrefix and statement[0] == ident"!" and statement[1] == ident"debugRoot":
      echo root.toStrLit
      continue
    elif statement.kind == nnkPrefix and statement[0] == ident"!" and statement[1] == ident"debugRootAndExit":
      echo root.toStrLit
      quit(QuitSuccess)
    elif statement.kind == nnkPrefix and statement[0] == ident"!" and statement[1] == ident"debugCurrent":
      echo result.toStrLit
      continue
    elif statement.kind == nnkPrefix and statement[0] == ident"!" and statement[1] == ident"debugCurrentAndExit":
      echo result.toStrLit
      quit(QuitSuccess)
    
    if statement.kind == nnkCall and statement[0] == ident"procCall" and inComponent:
      result.add(statement)
    elif statement.kind == nnkCall and statement[0] == ident"nim" and statement.len == 2 and statement[1].kind == nnkStmtList:
      # Real Nim code
      result.add(newStmtList(
        statement[1],
        newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true))
      ))
    
    elif statement.kind == nnkCall and statement[0] == ident"rawHtml":
      var node: NimNode
      if statement[1].kind in nnkStrLit..nnkTripleStrLit:
        node = statement[1]
      elif statement[1].kind == nnkStmtList and statement[1][0].kind in nnkStrLit..nnkTripleStrLit:
        node = statement[1][0]
      else:
        throwDefect(
          HpxBuildHtmlDefect,
          "rawHtml allows only static string! ",
          lineInfoObj(statement[1])
        )
      result.add(newCall("tagFromString", node))

    elif statement.kind == nnkCall and statement[0].kind != nnkPrefix:
      let
        tagName =
          if statement[0].kind in AtomicNodes:
            newLit(getTagName($statement[0]))
          elif statement[0].kind in [nnkBracketExpr, nnkDotExpr]:
            newLit(getTagName($statement[0][0]))
          else:
            newLit""
        statementList = statement[^1]
        compName =
          if statement[0].kind in AtomicNodes:
            statement[0]
          else:
            statement[0][0]
        whenStmt = newNimNode(nnkWhenStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall(
              "and",
              newCall("declared", compName),
              newCall("not", newCall("contains", ident"htmlTagsList", tagName))
            )
          ),
          newNimNode(nnkElse)
        )
        compStatement = newNimNode(nnkCommand).add(ident"component", statement)
      var attrs = newNimNode(nnkTableConstr)
      # tag(attr="value"):
      #   ...
      if statement.len-2 > 0 and statementList.kind == nnkStmtList:
        var builded = buildHtmlProcedure(tagName, statementList, inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars)
        for attr in statement[1 .. statement.len-2]:
          if attr.kind in AtomicNodes:
            # component params
            builded.addAttribute(
              attr,
              formatNode(attr),
              inComponent
            )
          else:
            builded.addAttribute(
              attr[0],
              formatNode(attr[1]),
              inComponent
            )
        whenStmt[1].add(builded)
      # tag(attr="value")
      elif statementList.kind != nnkStmtList and statement[0] != ident"@":
        for attr in statement[1 .. statement.len-1]:
          attrs.add(attribute(attr, inComponent))
        if attrs.len > 0:
          whenStmt[1].add(newCall("initTag", tagName, newCall("newStringTable", attrs)))
        else:
          whenStmt[1].add(newCall("initTag", tagName))
      # tag:
      #   ...
      else:
        whenStmt[1].add(buildHtmlProcedure(tagName, statementList, inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars))
      
      # Component detect
      if statement[0].kind in {nnkIdent, nnkDotExpr, nnkBracketExpr} and statement[0] notin [ident"@", ident":="] and statement[^1].kind == nnkStmtList:
        let componentData = "data_" & $compName.toStrLit
        whenStmt[0].add(
          newNimNode(nnkWhenStmt).add(
            newNimNode(nnkElifBranch).add(
              newCall(
                "and",
                newCall("declared", compName),
                newCall("is", compName, ident"TagRef")
              ),
              if statement[^1].kind == nnkStmtList:
                newStmtList(
                  newVarStmt(ident"_anonymousTag", statement[0]),
                  newCall(
                    "add",
                    ident"_anonymousTag",
                    newCall("buildHtml", statementList)
                    # buildHtmlProcedure(
                    #   ident"div", statementList, inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars
                    # ).add(newNimNode(nnkExprEqExpr).add(ident"onlyChildren", newLit(true)))
                  ),
                  ident"_anonymousTag"
                )
              else:
                statement[0]
            ),
            newNimNode(nnkElifBranch).add(
              newCall(
                "and",
                newCall("declared", compName),
                newCall("is", compName, newNimNode(nnkProcTy)),
              ), newStmtList(
                block:
                  var call = newCall(compName)
                  for i in statement[1..^2]:
                    call.add(i)
                  call.add(newNimNode(nnkExprEqExpr).add(ident"stmt", newCall("buildHtml", statement[^1])))
                  call
              )
            ),
            newNimNode(nnkElifBranch).add(
              newCall(
                "and",
                newCall("declared", compName),
                newCall("not", newCall("is", compName, ident"typedesc")),
              ),
              newStmtList(
                newLetStmt(
                  ident(componentData),
                  newCall("render", compName)
                ),
                newCall(
                  "addArgIter",
                  ident(componentData),
                  newCall("&", newLit"data-", newDotExpr(compName, ident(UniqueComponentId)))
                ),
                when defined(js):
                  newStmtList(
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newLit(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newLit(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newLit(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
                    )),
                  )
                else:
                  newEmptyNode(),
                ident(componentData)
              )),
            newNimNode(nnkElse).add(
              useComponent(compStatement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars, true)
            )
          ))
      # Component constructor
      elif compName.kind == nnkInfix and compName[0] == ident"->":
        whenStmt[0].add(useComponent(compStatement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars, constructor = true))
      # Component default constructor
      else:
        whenStmt[0].add(
          newNimNode(nnkWhenStmt).add(
            newNimNode(nnkElifBranch).add(
              newCall(
                "and",
                newCall("declared", compName),
                newCall("is", compName, newNimNode(nnkProcTy)),
              ), newStmtList(
                block:
                  var call = newCall(compName)
                  for i in statement[1..^1]:
                    call.add(i)
                  call
              )
            ), newNimNode(nnkElse).add(
              useComponent(compStatement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars)
            )
          )
        )
      
      result.add(whenStmt)
    
    # Component usage
    # deprecated keyword `component` support:
    elif statement.kind == nnkCommand and statement[0] == ident"component":
      # Component without arguments
      if statement[1].kind in {nnkIdent, nnkDotExpr, nnkBracketExpr}:
        let componentData = "data_" & $statement[1].toStrLit
        result.add(
          newNimNode(nnkWhenStmt).add(
            newNimNode(nnkElifBranch).add(
              newCall("not", newCall("is", statement[1], ident"typedesc")),
              newStmtList(
                newLetStmt(
                  ident(componentData),
                  newCall("render", statement[1])
                ),
                newCall(
                  "addArgIter",
                  ident(componentData),
                  newCall("&", newLit"data-", newDotExpr(statement[1], ident(UniqueComponentId)))
                ),
                when defined(js):
                  newStmtList(
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newLit(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newLit(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newLit(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
                    )),
                  )
                else:
                  newEmptyNode(),
                ident(componentData)
              )),
            newNimNode(nnkElse).add(
              useComponent(statement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars, true)
            )
          ))
      # Component constructor
      elif statement[1].kind == nnkInfix and statement[1][0] == ident"->":
        result.add(useComponent(statement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars, constructor = true))
      # Component default constructor
      else:
        result.add(useComponent(statement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars))
    
    elif statement.kind in [nnkStrLit, nnkTripleStrLit]:
      # "Raw text"
      when enableAutoTranslate:
        result.add(newCall("initTag", newNimNode(nnkWhenStmt).add(
            newNimNode(nnkElifBranch).add(
              newCall("declared", ident"translates"),
              newCall("translate", formatNode(statement))
            ), newNimNode(nnkElse).add(
              formatNode(statement)
            )
        ), newLit(true)))
      else:
        result.add(newCall("initTag", formatNode(statement), newLit(true)))
    
    elif statement.kind in [nnkVarSection, nnkLetSection, nnkConstSection]:
      # Nim variable declaration
      result.add(newStmtList(
        statement,
        newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true))
      ))
    
    elif statement.kind == nnkInfix and statement[0] == ident":=":
      # Attributes
      result.addAttribute(
        statement[1],
        if statement[2].kind in {nnkIntLit..nnkFloat128Lit}: statement[2].toStrLit else: statement[2],
        inComponent
      )
    
    elif statement.kind == nnkAsgn:
      # Var reassign
      result.add(newStmtList(
        statement,
        newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true))
      ))
    
    elif statement.kind in {nnkBind, nnkBindStmt, nnkMixinStmt}:
      # binds/mixins
      result.add(newStmtList(
        statement,
        newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true))
      ))
    
    # !DOCTYPE html
    elif statement.kind == nnkPrefix and statement[0] == ident"!" and statement[1].kind == nnkCommand and ($statement[1][0]).toLower() == "doctype":
      result.add(newStmtList(
        newLetStmt(
          ident"_doctype",
          newCall("initTag", newLit"!DOCTYPE", newCall("@", bracket()))
        ),
        newCall("[]=", ident"_doctype", newLit"html", newLit""),
        ident"_doctype"
      ))
    
    # Events handling
    elif (statement.kind == nnkPrefix and statement[0] == ident"@") or (statement.kind == nnkCall and statement[0].kind == nnkPrefix and statement[0][0] == ident"@"):
      let
        event =
          if statement.kind == nnkCall:
            $statement[0][1]
          else:
            $statement[1]
        evname = if event.startsWith("on"): event else: "on" & event
        args = newNimNode(nnkFormalParams).add(
          newEmptyNode()
        )
        procedure = newLambda(newStmtList(), args)

      when defined(js):
        if statement.len == 4 and statement.kind == nnkPrefix:
          args.add(newIdentDefs(statement[2], ident"Event"))
        elif statement.len == 3 and statement.kind == nnkCall:
          args.add(newIdentDefs(statement[1], ident"Event"))
        else:
          args.add(newIdentDefs(ident"ev", ident"Event", newNilLit()))
      else:
        if statement.len == 4 and statement.kind == nnkPrefix:
          args.add(newIdentDefs(statement[2], ident"JsonNode"))
        elif statement.len == 3 and statement.kind == nnkCall:
          args.add(newIdentDefs(statement[1], ident"JsonNode"))
        else:
          args.add(newIdentDefs(ident"ev", ident"JsonNode", newCall("newJObject")))
      
      if inComponent:
        procedure.body = statement[^1]
        procedure.body.insert(0, newVarStmt(ident"self", newCall(componentName, ident"self")))
        when not defined(js):
          args.insert(1, newIdentDefs(ident"self", ident"BaseComponent"))
        # Detect in component and in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & ")}"
            registerEvent = fmt"registerEventScoped{uniqueId.value}{uniqueId.value+2}"
            callRegister = newCall(registerEvent)
          when defined(js):
            var procParams: seq[string] = @[]
          else:
            var procParams = @[ident"ComponentEventHandler"]
          for i in cycleVars:
            when defined(js):
              procParams.add("`" & $i & "`")
            else:
              procParams.add(newIdentDefs(i, ident"auto"))
            callRegister.add(i)
          when defined(js):
            procedure.body.insert(0, newNimNode(nnkPragma).add(
              newNimNode(nnkExprColonExpr).add(
                ident"emit", newLit("`" & $args[^1][0] & "` = event;")
              )
            ))
            procedure.body.insert(0, newNimNode(nnkVarSection).add(
              newIdentDefs(args[^1][0], ident"Event", newEmptyNode())
            ))
            events.add(newStmtList(
              newNimNode(nnkPragma).add(
                newNimNode(nnkExprColonExpr).add(
                  ident"emit", newLit("const __elSc" & $elemEventId & " = (" & procParams.join(",") & ") => {")
                )
              ),
              newCall(
                "eventListener", ident("__el" & $elemEventId), newLit(event),
                newNimNode(nnkBlockStmt).add(newEmptyNode(), procedure.body)
              ),
              newNimNode(nnkPragma).add(
                newNimNode(nnkExprColonExpr).add(
                  ident"emit", newLit("};\n__elSc" & $elemEventId & "(" & procParams.join(",") & ");")
                )
              ),
            ))
          else:
            result.addAttribute(
              newLit(evname),
              newCall(
                "fmt",
                newLit(
                  "callComponentEventHandler('{self." & UniqueComponentId & "}', {-(" &
                  fmt"{uniqueId.value}" & cycleVar & ", event)"
                )
              )
            )
            result.add(
              newStmtList(
                newProc(ident(registerEvent), procParams, procedure),
                newCall(
                  "[]=",
                  ident"componentEventHandlers",
                  newCall("-", newCall("+", newLit(uniqueId.value), ident(cycleTmpVar))),
                  callRegister
                ),
                newCall("inc", ident(cycleTmpVar)),
                newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true)),
              )
            )
        # In component and not in cycle
        else:
          when defined(js):
            procedure.body.insert(0, newNimNode(nnkPragma).add(
              newNimNode(nnkExprColonExpr).add(
                ident"emit", newLit("`" & $args[^1][0] & "` = event;")
              )
            ))
            procedure.body.insert(0, newNimNode(nnkVarSection).add(
              newIdentDefs(args[^1][0], ident"Event", newEmptyNode())
            ))
            events.add(
              newCall("eventListener", ident("__el" & $elemEventId), newLit(event),
              newNimNode(nnkBlockStmt).add(
                newEmptyNode(), procedure.body
              ))
            )
          else:
            result.addAttribute(
              newLit(evname),
              newCall(
                "fmt",
                newLit(
                  "callComponentEventHandler('{self." & UniqueComponentId & "}', " & fmt"{uniqueId.value}, event)"
                )
              )
            )
            result.add(newStmtList(
              newCall("once",
                newCall("[]=", ident"componentEventHandlers", newLit(uniqueId.value), procedure)
              ), newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true))
            ))
        procedure.body.insert(0, newAssignment(ident"currentComponent", newCall("fmt", newLit"{self.uniqCompId}")))
        procedure.body.add(newAssignment(ident"currentComponent", newLit""))
      else:
        procedure.body = statement[^1]
        # not in component but in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & ")}"
            registerEvent = fmt"registerEventScoped{uniqueId.value}{uniqueId.value+2}"
            callRegister = newCall(registerEvent)
          when defined(js):
            var procParams: seq[string] = @[]
          else:
            var procParams = @[ident"AppEventHandler"]
          for i in cycleVars:
            when defined(js):
              procParams.add("`" & $i & "`")
            else:
              procParams.add(newIdentDefs(i, ident"auto"))
            callRegister.add(i)
          when defined(js):
            procedure.body.insert(0, newNimNode(nnkPragma).add(
              newNimNode(nnkExprColonExpr).add(
                ident"emit", newLit("`" & $args[^1][0] & "` = event;")
              )
            ))
            procedure.body.insert(0, newNimNode(nnkVarSection).add(
              newIdentDefs(args[^1][0], ident"Event", newEmptyNode())
            ))
            events.add(newStmtList(
              newNimNode(nnkPragma).add(
                newNimNode(nnkExprColonExpr).add(
                  ident"emit", newLit("const __elSc" & $elemEventId & " = (" & procParams.join(",") & ") => {")
                )
              ),
              newCall(
                "eventListener", ident("__el" & $elemEventId), newLit(event),
                newNimNode(nnkBlockStmt).add(newEmptyNode(), procedure.body)
              ),
              newNimNode(nnkPragma).add(
                newNimNode(nnkExprColonExpr).add(
                  ident"emit", newLit("};\n__elSc" & $elemEventId & "(" & procParams.join(",") & ");")
                )
              ),
            ))
          else:
            result.addAttribute(
              newLit(evname),
              newCall(
                "fmt",
                newLit("callEventHandler({-(" & fmt"{uniqueId.value}" & cycleVar & ", event)")
              )
            )
            result.add(
              newStmtList(
                newProc(ident(registerEvent), procParams, procedure),
                newCall(
                  "[]=",
                  ident"eventHandlers",
                  newCall("-", newCall("+", newLit(uniqueId.value), ident(cycleTmpVar))),
                  callRegister
                ),
                newCall("inc", ident(cycleTmpVar)),
                newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true))
              )
            )
        # not in component and not in cycle
        else:
          when defined(js):
            procedure.body.insert(0, newNimNode(nnkPragma).add(
              newNimNode(nnkExprColonExpr).add(
                ident"emit", newLit("`" & $args[^1][0] & "` = event;")
              )
            ))
            procedure.body.insert(0, newNimNode(nnkVarSection).add(
              newIdentDefs(args[^1][0], ident"Event", newEmptyNode())
            ))
            events.add(
              newCall("eventListener", ident("__el" & $elemEventId), newLit(event),
              newNimNode(nnkBlockStmt).add(
                newEmptyNode(), procedure.body
              ))
            )
          else:
            result.addAttribute(
              newLit(evname),
              newLit(fmt"callEventHandler({uniqueId.value}, event)")
            )
            result.add(newStmtList(
              newCall("once",
                newCall("[]=", ident"eventHandlers", newLit(uniqueId.value), procedure)
              ),
              newCall("initTag", newLit"div", newCall("@", newNimNode(nnkBracket)), newLit(true))
            ))
      # echo result.toStrLit
      # if events.len > 0:
      # echo events.len
      # echo "NEW EVENT: ", events[^1].toStrLit
      inc uniqueId
    
    elif statement.kind in {nnkIdent, nnkBracketExpr, nnkDotExpr} and statement notin [ident"@", ident":="]:
      let
        compName = statement
        compStatement = newNimNode(nnkCommand).add(ident"component", statement)
        whenStmt = newNimNode(nnkWhenStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall("not", newCall("contains", ident"htmlTagsList", newLit(getTagName($compName.toStrLit))))
          ),
          newNimNode(nnkElse)
        )
      if statement == ident"slot":
        # slot
        let
          cycleCounter =
            if cycleTmpVar == "":
              newLit(0)
            else:
              ident(cycleTmpVar)
          compCounter =
            if compTmpVar == newEmptyNode():
              newLit""
            else:
              compTmpVar
          cmpName =
            if componentName == newEmptyNode():
              newLit""
            else:
              newLit($componentName)
        whenStmt[1].add(newStmtList(
          newVarStmt(ident"cclCounter", cycleCounter),
          newCall(
            newDotExpr(ident"self", ident"slot"),
            ident"self",
            newLit(inComponent),
            cmpName,
            newLit(inCycle),
            ident"cclCounter",
            compCounter
          )
        ))
      else:
        # tag
        whenStmt[1].add(newCall("tag", newLit(getTagName($statement.toStrLit))))
      
      
      # Component detect
      let componentData = "data_" & $compName.toStrLit
      whenStmt[0].add(
        newNimNode(nnkWhenStmt).add(
          newNimNode(nnkElifBranch).add(
            newCall(
              "and",
              newCall("declared", statement),
              newCall("is", statement, ident"TagRef")
            ), newStmtList(
              statement
            )
          ),
          newNimNode(nnkElifBranch).add(
            newCall(
              "and",
              newCall("declared", compName),
              newCall("is", compName, newNimNode(nnkProcTy)),
            ), newStmtList(
              block:
                var call = newCall(compName)
                call
            )
          ),
          newNimNode(nnkElifBranch).add(
            newCall("not", newCall("is", compName, ident"typedesc")),
            newStmtList(
              newLetStmt(
                ident(componentData),
                newCall("render", compName)
              ),
              newCall(
                "addArgIter",
                ident(componentData),
                newCall("&", newLit"data-", newDotExpr(compName, ident(UniqueComponentId)))
              ),
              when defined(js):
                newStmtList(
                  newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                    ident"emit",
                    newLit(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
                  )),
                  newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                    ident"emit",
                    newLit(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
                  )),
                  newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                    ident"emit",
                    newLit(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
                  )),
                )
              else:
                newEmptyNode(),
              ident(componentData)
            )),
          newNimNode(nnkElse).add(
            useComponent(compStatement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars, true)
          )
        ))
      
      result.add(whenStmt)
    
    elif statement.kind == nnkAccQuoted:
      # `tag`
      result.add(newCall("tag", newLit(getTagName($statement[0]))))
    
    elif statement.kind == nnkCurly and statement.len == 1:
      # variables and procedures
      result.add(newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
        newCall(
          "is", statement[0], ident"TagRef"
        ),
        statement[0]
      ), newNimNode(nnkElse).add(
        newCall("initTag", newCall("$", statement[0]), newLit(true))
      )))
    
    # if-elif or case-of
    elif statement.kind in [nnkCaseStmt, nnkIfStmt, nnkIfExpr, nnkWhenStmt]:
      let start =
        if statement.kind == nnkCaseStmt:
          1
        else:
          0
      for i in start..<statement.len:
        if statement[i][^1].kind == nnkStmtList:
          statement[i][^1] = buildHtmlProcedure(
            ident"div", statement[i][^1], inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars
          ).add(newLit(true))
        elif statement[i][^1].kind in nnkCallKinds:
          statement[i][^1] = buildHtmlProcedure(
            ident"div", newStmtList(statement[i][^1]), inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars
          ).add(newLit(true))
        elif statement[i][^1].kind in {nnkWhenStmt, nnkIfStmt, nnkIfExpr}:
          for branch in 0..<statement[i][^1].len:
            statement[i][^1][branch][^1] = buildHtmlProcedure(
              ident"div", statement[i][^1][branch][^1], inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars
            ).add(newLit(true))
      if statement[^1].kind != nnkElse:
        statement.add(newNimNode(nnkElse).add(newNilLit()))
      result.add(statement)
    
    # while ...:
    #   ...
    elif statement.kind == nnkWhileStmt:
      let
        condition = statement[0]
        body = statement[1]
      result.add(newCall(
        ident"initTag",
        newLit"div",
        newStmtList(
          newVarStmt(ident"_while_result", newCall(newNimNode(nnkBracketExpr).add(ident"newSeq", ident"TagRef"))),
          newNimNode(nnkWhileStmt).add(
            condition,
            newCall(
              "add",
              ident"_while_result",
              newStmtList(
                newVarStmt(ident"__while__res", buildHtmlProcedure(ident"div", body, inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars)),
                newAssignment(newDotExpr(ident"__while__res", ident"onlyChildren"), newLit(true)),
                ident"__while__res"
              )
            )
          ),
          ident"_while_result"
        ),
        newLit(true)
      ))
    
    # for ... in ...:
    #   ...
    elif statement.kind == nnkForStmt:
      var
        unqn = fmt"c{uniqueId.value}"
        cycleName = ident(fmt"__r{uniqueId.value}")
      # extract cycle variables
      for i in 0..statement.len-3:
        cycleVars.add statement[i]
      inc uniqueId
      if cycleTmpVar == "" or cycleTmpVar == "cycleCounter":
        statement[^1] = newStmtList(
          newCall(
            "add",
            cycleName,
            buildHtmlProcedure(ident"div", statement[^1], inComponent, componentName, true, unqn, compTmpVar, cycleVars).add(
              newLit(true)
            )
          ),
        )
      else:
        statement[^1] = newStmtList(
          newCall(
            "add",
            cycleName,
            buildHtmlProcedure(ident"div", statement[^1], inComponent, componentName, true, cycleTmpVar, compTmpVar, cycleVars).add(
              newLit(true)
            )
          ),
        )
      for i in 0..statement.len-3:
        discard cycleVars.pop()
      if cycleTmpVar == "" or cycleTmpVar == "cycleCounter":
        statement[^1].insert(0, newCall("inc", ident(unqn)))
      else:
        statement[^1].insert(0, newCall("inc", ident(cycleTmpVar)))
      result.add(
        newCall(
          "initTag",
          newLit"div",
          newStmtList(
            if cycleTmpVar == "" or cycleTmpVar == "cycleCounter":
              newVarStmt(ident(unqn), newLit(0))
            else:
              newEmptyNode(),
            newVarStmt(
              cycleName,
              newCall(newNimNode(nnkBracketExpr).add(ident"newSeq", ident"TagRef"))
            ),
            statement,
            cycleName,
          ),
          newLit(true)
        )
      )
    elif statement.kind == nnkStmtList:
      var builded = buildHtmlProcedure(ident"div", statement, inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars)
      result.add(builded)
    else:
      throwDefect(
        HpxBuildHtmlDefect,
        "invalid syntax: ",
        lineInfoObj(statement)
      )
  
  # varargs -> seq
  if result.len > 2:
    if result[2].kind == nnkCall and $result[2][0] == "newStringTable":
      var
        tagRefs = result[3..result.len-1]
        arr = newNimNode(nnkBracket)
      result.del(3, result.len - 3)
      for tag in tagRefs:
        arr.add(tag)
      result.add(newCall("@", arr))
    else:
      var
        tagRefs = result[2..result.len-1]
        arr = newNimNode(nnkBracket)
      result.del(2, result.len - 2)
      for tag in tagRefs:
        arr.add(tag)
      result.add(newCall("@", arr))
  if events.len > 0:
    inc uniqueId, -1
    result = newStmtList(
      newVarStmt(ident("__el" & $elemEventId), result.copy())
    )
    for i in events:
      result.add(i)
    result.add(ident("__el" & $elemEventId))
    inc uniqueId
