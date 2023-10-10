## # Macro Utils
## 
## ## ⚠ Warning: This Module Is LOW-LEVEL API ⚠
## 
import
  regex,
  strutils,
  strformat,
  macros,
  macrocache,
  ../core/[exceptions, constants]


# Compile time variables
const
  uniqueId* = CacheCounter"uniqueId"
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
                         cycleVars: var seq[NimNode]): NimNode


proc bracket*(node: varargs[NimNode]): NimNode =
  result = newNimNode(nnkBracket)
  for i in node:
    result.add(i)


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
  if re2"^tag[A-Z]" in name:
    name[3..^1].toLower()
  elif re2"^[ht][A-Z]" in name:
    name[1..^1].toLower()
  else:
    name


proc formatNode*(node: NimNode): NimNode =
  if node.kind == nnkStrLit:
    newCall("fmt", node)
  else:
    node


proc useComponent*(statement: NimNode, inCycle, inComponent: bool,
                   cycleTmpVar: string, compTmpVar: NimNode, cycleVars: var seq[NimNode],
                   returnTagRef: bool = true, constructor: bool = false,
                   nameIsIdent: bool = false): NimNode =
  let
    name =
      if statement[1].kind == nnkCall:
        statement[1][0]
      elif statement[1].kind == nnkInfix:
        statement[1][1]
      else:
        statement[1]
    componentName = fmt"comp{uniqueId.value}{uniqueId.value + 2}{uniqueId.value * 2}{uniqueId.value + 7}"
    componentNameIdent =
      if cycleTmpVar == "" and compTmpVar.kind == nnkEmpty:
        newLit(componentName)
      elif compTmpVar.kind == nnkEmpty and cycleTmpVar != "":
        newCall("&", newLit(componentName), newCall("$", ident(cycleTmpVar)))
      elif cycleTmpVar == "" and compTmpVar.kind != nnkEmpty:
        newCall("&", newLit(componentName), newCall("$", compTmpVar))
      else:
        newCall("&", newLit(componentName), newCall("&", newCall("$", compTmpVar), newCall("$", ident(cycleTmpVar))))
    objConstr =
      if constructor:
        newCall(fmt"constructor_{name}")
      else:
        newCall(fmt"init{name.toStrLit}")
    componentNameTmp = "_" & componentName
    componentData = "data_" & componentName
    stringId =
      when defined(js):
        if inCycle or inComponent:
          componentNameIdent
        else:
          newLit(componentName)
      else:
        if inCycle or inComponent:
          newCall("&", ident"hostname", componentNameIdent)
        else:
          newCall("&", ident"hostname", newLit(componentName))
    componentSlot =
      if statement.len > 1 and statement[^1].kind == nnkStmtList:
        statement[^1]
      else:
        newStmtList()
  inc uniqueId
  objConstr.add(stringId)
  if statement[1].kind == nnkCall:
    for i in 1..<statement[1].len:
      # call -> arg
      objConstr.add(statement[1][i])
  # Constructor
  elif statement[1].kind == nnkInfix and statement[1][0] == ident"->":
    for i in 1..<statement[1][2].len:
      # infix -> call -> arg
      objConstr.add(statement[1][2][i])
  result = newStmtList(
    newVarStmt(ident(componentNameTmp), objConstr),
    newVarStmt(
      ident(componentName),
      newCall(
        name,
        newCall("registerComponent", stringId, ident(componentNameTmp))
      )
    ),
    newAssignment(
      newDotExpr(ident(componentName), ident"slot"),
      buildHtmlProcedure(
        ident"div", componentSlot, inComponent, ident(componentName), inCycle, cycleTmpVar, newLit(componentName), cycleVars
      ).add(newNimNode(nnkExprEqExpr).add(ident"onlyChildren", newLit(true)))
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
        newCall("&", newStrLitNode("data-"), newDotExpr(ident(componentName), ident(UniqueComponentId)))
      )
    else:
      newEmptyNode(),
    when defined(js):
      if returnTagRef:
        newStmtList(
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident"emit",
            newStrLitNode(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
          )),
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident"emit",
            newStrLitNode(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
          )),
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident"emit",
            newStrLitNode(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
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
      if re2"^(answer|echo|styledEcho|styledWrite|write|await)" in fnName.toLower():
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


proc replaceUseInComponent*(body: NimNode) =
  for statement in body:
    if statement.kind in nnkCallKinds and statement[0] == ident"use" and statement.len == 2:
      statement.add(newLit(true))
      statement.add(ident"uniqCompId")
    elif statement.kind notin AtomicNodes:
      statement.replaceUseInComponent()


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
    newColonExpr(newLit("_"), formatNode(attr))
  else:
    var
      k = ($attr[0]).toLower()
      v =
        if k == "id" and attr[1].kind in {nnkStrLit, nnkTripleStrLit} and inComponent:
          newLit($attr[1] & "{self.uniqCompId}")
        elif k == "id" and attr[1].kind in CallNodes and attr[1][0] == ident"fmt" and inComponent:
          newCall("fmt", newLit($attr[1][1] & "{self.uniqCompId}"))
        else:
          attr[1]
    newColonExpr(
      newLit($attr[0]),
      formatNode(v)
    )


proc addAttribute*(node, key, value: NimNode, inComponent: bool = false) =
  var
    k = ($key).toLower()
    v =
      if k == "id" and value.kind in {nnkStrLit, nnkTripleStrLit} and inComponent:
        newLit($value & "{self.uniqCompId}")
      elif k == "id" and value.kind in CallNodes and value[0] == ident"fmt" and inComponent:
        newCall("fmt", newLit($value[1] & "{self.uniqCompId}"))
      else:
        value
  if node.len == 2:
    node.add(newCall("newStringTable", newNimNode(nnkTableConstr).add(
      newColonExpr(newLit($key), v)
    )))
  elif node[2].kind == nnkCall and node[2][0] == ident"newStringTable":
    node[2][1].add(newColonExpr(newLit($key), v))
  else:
    node.insert(2, newCall("newStringTable", newNimNode(nnkTableConstr).add(
      newColonExpr(newLit($key), v)
    )))


proc endsWithBuildHtml*(statement: NimNode): bool =
  statement[^1].kind == nnkCall and $statement[^1][0] == "buildHtml"


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
                         cycleVars: var seq[NimNode]): NimNode =
  ## Builds HTML
  ## 
  ## Here you can use components and event handlers
  let elementName = newStrLitNode(getTagName($root))
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
        newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
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
        tagName = newStrLitNode(getTagName($statement[0]))
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
              newCall("not", newCall("contains", ident"htmlTagsList", newLit(getTagName($compName.toStrLit))))
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
              newStrLitNode($attr.toStrLit),
              formatNode(attr),
              inComponent
            )
          else:
            builded.addAttribute(
              newStrLitNode($attr[0]),
              formatNode(attr[1]),
              inComponent
            )
        whenStmt[1].add(builded)
      # tag(attr="value")
      elif statementList.kind != nnkStmtList:
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
      if statement[0].kind in {nnkIdent, nnkDotExpr, nnkBracketExpr}:
        let componentData = "data_" & $compName.toStrLit
        whenStmt[0].add(
          newNimNode(nnkWhenStmt).add(
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
                  newCall("&", newStrLitNode("data-"), newDotExpr(compName, ident(UniqueComponentId)))
                ),
                when defined(js):
                  newStmtList(
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newStrLitNode(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newStrLitNode(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newStrLitNode(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
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
        whenStmt[0].add(useComponent(compStatement, inCycle, inComponent, cycleTmpVar, compTmpVar, cycleVars))
      
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
                  newCall("&", newStrLitNode("data-"), newDotExpr(statement[1], ident(UniqueComponentId)))
                ),
                when defined(js):
                  newStmtList(
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newStrLitNode(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newStrLitNode(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
                    )),
                    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                      ident"emit",
                      newStrLitNode(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
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
        newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
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
        newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
      ))
    
    elif statement.kind in {nnkBind, nnkBindStmt, nnkMixinStmt}:
      # binds/mixins
      result.add(newStmtList(
        statement,
        newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
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
        args.insert(1, newIdentDefs(ident"self", ident"BaseComponent"))
        # Detect in component and in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & ")}"
            registerEvent = fmt"registerEventScoped{uniqueId.value}{uniqueId.value+2}"
            callRegister = newCall(registerEvent)
          var procParams = @[ident"ComponentEventHandler"]
          for i in cycleVars:
            procParams.add(newIdentDefs(i, ident"any"))
            callRegister.add(i)
          result.addAttribute(
            newStrLitNode(evname),
            newCall(
              "fmt",
              newStrLitNode(
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
                newCall("-", newCall("+", newIntLitNode(uniqueId.value), ident(cycleTmpVar))),
                callRegister
              ),
              newCall("inc", ident(cycleTmpVar)),
              newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
            )
          )
        # In component and not in cycle
        else:
          result.addAttribute(
            newStrLitNode(evname),
            newCall(
              "fmt",
              newStrLitNode(
                "callComponentEventHandler('{self." & UniqueComponentId & "}', " & fmt"{uniqueId.value}, event)"
              )
            )
          )
          result.add(newStmtList(
            newCall("once",
              newCall("[]=", ident"componentEventHandlers", newIntLitNode(uniqueId.value), procedure)
            ), newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
          ))
        procedure.body.insert(0, newAssignment(ident"currentComponent", newCall("fmt", newStrLitNode("{self.uniqCompId}"))))
        procedure.body.add(newAssignment(ident"currentComponent", newStrLitNode("")))
      else:
        procedure.body = statement[^1]
        # not in component but in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & ")}"
            registerEvent = fmt"registerEventScoped{uniqueId.value}{uniqueId.value+2}"
            callRegister = newCall(registerEvent)
          var procParams = @[ident"AppEventHandler"]
          for i in cycleVars:
            procParams.add(newIdentDefs(i, ident"any"))
            callRegister.add(i)
          result.addAttribute(
            newStrLitNode(evname),
            newCall(
              "fmt",
              newStrLitNode("callEventHandler({-(" & fmt"{uniqueId.value}" & cycleVar & ", event)")
            )
          )
          result.add(
            newStmtList(
              newProc(ident(registerEvent), procParams, procedure),
              newCall(
                "[]=",
                ident"eventHandlers",
                newCall("-", newCall("+", newIntLitNode(uniqueId.value), ident(cycleTmpVar))),
                callRegister
              ),
              newCall("inc", ident(cycleTmpVar)),
              newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
            )
          )
        # not in component and not in cycle
        else:
          result.addAttribute(
            newStrLitNode(evname),
            newStrLitNode(fmt"callEventHandler({uniqueId.value}, event)")
          )
          result.add(newStmtList(
            newCall("once",
              newCall("[]=", ident"eventHandlers", newIntLitNode(uniqueId.value), procedure)
            ), newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
          ))
      inc uniqueId
    
    elif statement.kind in {nnkIdent, nnkBracketExpr, nnkDotExpr}:
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
        if not inComponent:
          throwDefect(
            HpxComponentDefect,
            fmt"Slots can be used only in components!",
            lineInfoObj(statement)
          )
        whenStmt[1].add(newDotExpr(ident"self", ident"slot"))
      else:
        # tag
        whenStmt[1].add(newCall("tag", newStrLitNode(getTagName($statement.toStrLit))))
      
      
      # Component detect
      let componentData = "data_" & $compName.toStrLit
      whenStmt[0].add(
        newNimNode(nnkWhenStmt).add(
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
                newCall("&", newStrLitNode("data-"), newDotExpr(compName, ident(UniqueComponentId)))
              ),
              when defined(js):
                newStmtList(
                  newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                    ident"emit",
                    newStrLitNode(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
                  )),
                  newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                    ident"emit",
                    newStrLitNode(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
                  )),
                  newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
                    ident"emit",
                    newStrLitNode(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
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
      result.add(newCall("tag", newStrLitNode(getTagName($statement[0]))))
    
    elif statement.kind == nnkCurly and statement.len == 1:
      # variables
      result.add(newCall("initTag", newCall("$", statement[0]), newLit(true)))
    
    # if-elif or case-of
    elif statement.kind in [nnkCaseStmt, nnkIfStmt, nnkIfExpr, nnkWhenStmt]:
      let start =
        if statement.kind == nnkCaseStmt:
          1
        else:
          0
      for i in start..<statement.len:
        statement[i][^1] = buildHtmlProcedure(
          ident"div", statement[i][^1], inComponent, componentName, inCycle, cycleTmpVar, compTmpVar, cycleVars
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
        newStrLitNode("div"),
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
        idents: seq[NimNode] = @[]
      # extract cycle variables
      for i in 0..statement.len-3:
        cycleVars.add statement[i]
      inc uniqueId
      if cycleTmpVar == "":
        statement[^1] = newStmtList(
          buildHtmlProcedure(ident"div", statement[^1], inComponent, componentName, true, unqn, compTmpVar, cycleVars)
        )
      else:
        statement[^1] = newStmtList(
          buildHtmlProcedure(ident"div", statement[^1], inComponent, componentName, true, cycleTmpVar, compTmpVar, cycleVars)
        )
      for i in 0..statement.len-3:
        discard cycleVars.pop()
      if cycleTmpVar == "":
        statement[^1].insert(0, newCall("inc", ident(unqn)))
      else:
        statement[^1].insert(0, newCall("inc", ident(cycleTmpVar)))
      statement[^1][^1].add(newLit(true))
      result.add(
        newCall(
          "initTag",
          newStrLitNode("div"),
          newStmtList(
            if cycleTmpVar == "":
              newVarStmt(ident(unqn), newLit(0))
            else:
              newEmptyNode(),
            newCall(
              "collect",
              ident"newSeq",
              newStmtList(
                statement
              )
            ),
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
