## # Macro Utils
## 
## ## ⚠ Warning: This Module Is LOW-LEVEL API ⚠
## 
import
  regex,
  strutils,
  strformat,
  macros,
  ../core/[exceptions, constants]


# Compile time variables
var
  uniqueId* {.compileTime.} = 0
let
  discardStmt* {. compileTime .} = newNimNode(nnkDiscardStmt).add(newEmptyNode())
const
  UniqueComponentId* = "uniqCompId"


{.push compileTime.}

proc buildHtmlProcedure*(root, body: NimNode, inComponent: bool = false,
                         componentName: NimNode = newEmptyNode(), inCycle: bool = false,
                         cycleTmpVar: string = ""): NimNode


proc bracket*(node: varargs[NimNode]): NimNode =
  result = newNimNode(nnkBracket)
  for i in node:
    result.add(i)


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
                   cycleTmpVar: string, cycleVars: seq[NimNode],
                   returnTagRef: bool = true, constructor: bool = false): NimNode =
  let
    name =
      if statement[1].kind == nnkCall:
        statement[1][0]
      elif statement[1].kind == nnkInfix:
        statement[1][1]
      else:
        statement[1]
    componentName = fmt"comp{uniqueId}{uniqueId + 2}{uniqueId * 2}{uniqueId + 7}"
    objConstr =
      if constructor:
        newCall(fmt"constructor_{name}")
      else:
        newCall(fmt"init{name}")
    componentNameTmp = "_" & componentName
    componentData = "data_" & componentName
    stringId =
      if inCycle:
        newCall("&", newStrLitNode(componentName), newCall("$", ident(cycleTmpVar)))
      else:
        newStrLitNode(componentName)
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
    when defined(js):
      newVarStmt(
        ident(componentName),
        newCall(
          name,
          newCall("registerComponent", stringId, ident(componentNameTmp))
        )
      )
    else:
      newVarStmt(
        ident(componentName), ident(componentNameTmp)
      ),
    newAssignment(
      newDotExpr(ident(componentName), ident"slot"),
      buildHtmlProcedure(
        ident"div", componentSlot, inComponent, ident(componentName), inCycle, cycleTmpVar
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


proc attribute*(attr: NimNode): NimNode =
  ## Converts `nnkExprEqExpr` to `nnkColonExpr`
  newColonExpr(
    newStrLitNode($attr[0]),
    formatNode(attr[1])
  )


proc addAttribute*(node, key, value: NimNode) =
  if node.len == 2:
    node.add(newCall("newStringTable", newNimNode(nnkTableConstr).add(
      newColonExpr(newStrLitNode($key), value)
    )))
  elif node[2].kind == nnkCall and $node[2][0] == "newStringTable":
    node[2][1].add(newColonExpr(newStrLitNode($key), value))
  else:
    node.insert(2, newCall("newStringTable", newNimNode(nnkTableConstr).add(
      newColonExpr(newStrLitNode($key), value)
    )))


proc endsWithBuildHtml*(statement: NimNode): bool =
  statement[^1].kind == nnkCall and $statement[^1][0] == "buildHtml"


proc replaceSelfComponent*(statement, componentName: NimNode, parent: NimNode = nil,
                           convert: bool = false, is_constructor: bool = false, is_field: bool = true) =
  let self = if convert: ident"self" else: newDotExpr(ident"self", componentName)
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
        i.replaceSelfComponent(componentName, statement, convert, is_constructor)
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
          statement.insert(idx+1, newCall("reRender", ident"self"))
    var idxes: seq[tuple[node: NimNode, idx: int]] = @[]
    for idx, i in statement.pairs:
      if i.kind == nnkCall and i[0].kind == nnkDotExpr and i[0][0] == ident"self":
        idxes.add((i, idx))
      else:
        i.replaceSelfComponent(componentName, statement, convert, is_constructor)
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


var cycleVars {.compileTime.}: seq[NimNode] = @[]


proc buildHtmlProcedure*(root, body: NimNode, inComponent: bool = false,
                         componentName: NimNode = newEmptyNode(), inCycle: bool = false,
                         cycleTmpVar: string = ""): NimNode =
  ## Builds HTML
  ## 
  ## Here you can use components and event handlers
  let elementName = newStrLitNode(getTagName($root))
  result = newCall("initTag", elementName)

  for statement in body:
    if statement.kind == nnkDiscardStmt:
      continue
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
      var attrs = newNimNode(nnkTableConstr)
      # tag(attr="value"):
      #   ...
      if statement.len-2 > 0 and statementList.kind == nnkStmtList:
        var builded = buildHtmlProcedure(tagName, statementList, inComponent, componentName, inCycle, cycleTmpVar)
        for attr in statement[1 .. statement.len-2]:
          builded.addAttribute(
            newStrLitNode($attr[0]),
            formatNode(attr[1])
          )
        result.add(builded)
      # tag(attr="value")
      elif statementList.kind != nnkStmtList:
        for attr in statement[1 .. statement.len-1]:
          attrs.add(attribute(attr))
        if attrs.len > 0:
          result.add(newCall("initTag", tagName, newCall("newStringTable", attrs)))
        else:
          result.add(newCall("initTag", tagName))
      # tag:
      #   ...
      else:
        result.add(buildHtmlProcedure(tagName, statementList, inComponent, componentName, inCycle, cycleTmpVar))
    
    elif statement.kind == nnkCommand:
      # Component usage
      if statement[0] == ident"component":
        # Component without arguments
        if statement[1].kind == nnkIdent:
          let componentData = "data_" & $statement[1]
          result.add(
            newNimNode(nnkWhenStmt).add(
              newNimNode(nnkElifBranch).add(
                newCall("and", newCall("declared", statement[1]), newCall("not", newCall("is", statement[1], ident"typedesc"))),
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
                useComponent(statement, inCycle, inComponent, cycleTmpVar, cycleVars)
              )
            ))
        # Component constructor
        elif statement[1].kind == nnkInfix and statement[1][0] == ident"->":
          result.add(useComponent(statement, inCycle, inComponent, cycleTmpVar, cycleVars, constructor = true))
        # Component default constructor
        else:
          result.add(useComponent(statement, inCycle, inComponent, cycleTmpVar, cycleVars))
    
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
    
    elif statement.kind == nnkAsgn:
      # Attributes
      result.addAttribute(statement[0], statement[1])
    
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
          args.add(newIdentDefs(statement[2], ident"int"))
        elif statement.len == 3 and statement.kind == nnkCall:
          args.add(newIdentDefs(statement[1], ident"int"))
        else:
          args.add(newIdentDefs(ident"ev", ident"int", newNilLit()))
      
      if inComponent:
        procedure.body = statement[^1]
        procedure.body.insert(0, newVarStmt(ident"self", newCall(componentName, ident"self")))
        args.insert(1, newIdentDefs(ident"self", ident"BaseComponent"))
        # Detect in component and in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & "}"
            registerEvent = fmt"registerEventScoped{uniqueId}{uniqueId+2}"
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
                "callComponentEventHandler('{self." & UniqueComponentId & "}', {" &
                fmt"{uniqueId}" & cycleVar & ", event)"
              )
            )
          )
          result.add(
            newStmtList(
              newProc(ident(registerEvent), procParams, procedure),
              newCall(
                "[]=",
                ident"componentEventHandlers",
                newCall("+", newIntLitNode(uniqueId), ident(cycleTmpVar)),
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
                "callComponentEventHandler('{self." & UniqueComponentId & "}', " & fmt"{uniqueId}, event)"
              )
            )
          )
          result.add(newStmtList(
            newCall("once",
              newCall("[]=", ident"componentEventHandlers", newIntLitNode(uniqueId), procedure)
            ), newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
          ))
        procedure.body.insert(0, newAssignment(ident"currentComponent", newCall("fmt", newStrLitNode("{self.uniqCompId}"))))
        procedure.body.add(newAssignment(ident"currentComponent", newStrLitNode("")))
      else:
        procedure.body = statement[^1]
        # not in component but in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & "}"
            registerEvent = fmt"registerEventScoped{uniqueId}{uniqueId+2}"
            callRegister = newCall(registerEvent)
          var procParams = @[ident"AppEventHandler"]
          for i in cycleVars:
            procParams.add(newIdentDefs(i, ident"any"))
            callRegister.add(i)
          result.addAttribute(
            newStrLitNode(evname),
            newCall(
              "fmt",
              newStrLitNode("callEventHandler({" & fmt"{uniqueId}" & cycleVar & ", event)")
            )
          )
          result.add(
            newStmtList(
              newProc(ident(registerEvent), procParams, procedure),
              newCall(
                "[]=",
                ident"eventHandlers",
                newCall("+", newIntLitNode(uniqueId), ident(cycleTmpVar)),
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
            newStrLitNode(fmt"callEventHandler({uniqueId}, event)")
          )
          result.add(newStmtList(
            newCall("once",
              newCall("[]=", ident"eventHandlers", newIntLitNode(uniqueId), procedure)
            ), newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
          ))
      inc uniqueId
    
    elif statement.kind == nnkIdent:
      if statement == ident"slot":
        # slot
        if not inComponent:
          throwDefect(
            HpxComponentDefect,
            fmt"Slots can be used only in components!",
            lineInfoObj(statement)
          )
        result.add(newDotExpr(ident"self", ident"slot"))
      else:
        # tag
        result.add(newCall("tag", newStrLitNode(getTagName($statement))))
    
    elif statement.kind == nnkAccQuoted:
      # `tag`
      result.add(newCall("tag", newStrLitNode(getTagName($statement[0]))))
    
    elif statement.kind == nnkCurly and statement.len == 1:
      # variables
      result.add(newCall("initTag", newCall("$", statement[0]), newLit(true)))
    
    # if-elif or case-of
    elif statement.kind in [nnkCaseStmt, nnkIfStmt, nnkIfExpr]:
      let start =
        if statement.kind == nnkCaseStmt:
          1
        else:
          0
      for i in start..<statement.len:
        statement[i][^1] = buildHtmlProcedure(
          ident"div", statement[i][^1], inComponent, componentName, inCycle, cycleTmpVar
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
                newVarStmt(ident"__while__res", buildHtmlProcedure(ident"div", body, inComponent, componentName, inCycle, cycleTmpVar)),
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
        unqn = fmt"tmpCycleIdx{uniqueId}"
        idents: seq[NimNode] = @[]
      # extract cycle variables
      for i in 0..statement.len-3:
        cycleVars.add statement[i]
      inc uniqueId
      statement[^1] = newStmtList(
        buildHtmlProcedure(ident"div", statement[^1], inComponent, componentName, true, unqn)
      )
      for i in 0..statement.len-3:
        discard cycleVars.pop()
      statement[^1].insert(0, newCall("inc", ident(unqn)))
      statement[^1][^1].add(newLit(true))
      result.add(
        newCall(
          "initTag",
          newStrLitNode("div"),
          newStmtList(
            newVarStmt(ident(unqn), newLit(0)),
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
