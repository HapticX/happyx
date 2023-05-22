## # Renderer
## 
## Provides a single-page application (SPA) renderer with reactivity features.
## It likely contains functions or classes that allow developers to
## dynamically update the content of a web page without reloading the entire page.
## 
## 
## ## Moving Between Routes
## To move to other location just use `route("/path")`
## 

import
  macros,
  logging,
  htmlgen,
  strtabs,
  sugar,
  strutils,
  strformat,
  tables,
  regex,
  ./tag,
  ../private/[cmpltime, macro_utils, exceptions],
  ../mounting/mounting,
  ../sugar/sgr

when defined(js):
  import
    dom,
    jsconsole
  export
    dom,
    jsconsole

export
  strformat,
  logging,
  htmlgen,
  strtabs,
  strutils,
  tables,
  regex,
  sugar,
  tag


type
  AppEventHandler* = proc()
  ComponentEventHandler* = proc(self: BaseComponent)
  App* = ref object
    appId*: cstring
    router*: proc(force: bool = false)
  BaseComponent* = ref BaseComponentObj
  BaseComponentObj* = object of RootObj
    uniqCompId*: string
    isCreated*: bool
    slot*: TagRef
    created*: ComponentEventHandler  ## Calls before first rendering
    exited*: ComponentEventHandler  ## Calls after last rendering
    updated*: ComponentEventHandler  ## Calls after every rendering
    pageHide*: ComponentEventHandler  ## Calls after every rendering
    pageShow*: ComponentEventHandler  ## Calls after every rendering
    beforeUpdated*: ComponentEventHandler  ## Calls before every rendering


# Global variables
var
  application*: App = nil
  eventHandlers* = newTable[int, AppEventHandler]()
  componentEventHandlers* = newTable[int, ComponentEventHandler]()
  components* = newTable[cstring, BaseComponent]()
  currentComponent* = ""
  currentRoute*: cstring = "/"

# Compile time variables
var
  uniqueId {.compileTime.} = 0

const
  UniqueComponentId = "uniqCompId"


when defined(js):
  {.emit: "function callEventHandler(idx) {".}
  var idx: int
  {.emit: "`idx` = idx;" .}
  eventHandlers[idx]()
  {.emit: "}" .}
  {.emit: "function callComponentEventHandler(componentId, idx) {".}
  var
    callbackIdx: int
    componentId: cstring
  {.emit: "`callbackIdx` = idx; `componentId` = componentId;" .}
  componentEventHandlers[callbackIdx](components[componentId])
  {.emit: "}" .}


{.push inline.}

proc route*(path: cstring) =
  when defined(js):
    {.emit: "window.history.pushState(null, null, '#' + `path`);" .}
    let force = currentRoute != path
    currentRoute = path
    application.router(force)


proc registerApp*(appId: cstring = "app"): App {. discardable .} =
  ## Creates a new Singla Page Application
  application = App(appId: appId)
  application


proc registerComponent*(name: cstring, component: BaseComponent): BaseComponent =
  if components.hasKey(name):
    return components[name]
  components[name] = component
  component


method render*(self: BaseComponent): TagRef {.base.} =
  ## Basic method that needs to overload
  nil


method reRender*(self: BaseComponent) {.base.} =
  ## Basic method that needs to overload
  discard

{.pop.}


template start*(app: App) =
  ## Starts single page application
  document.addEventListener("DOMContentLoaded", onDOMContentLoaded)
  window.addEventListener("popstate", onDOMContentLoaded)
  {. emit: "if (window.location.href.split('#').length == 1) {" .}
  route("/")
  {. emit: "}" .}


{.push compileTime.}

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


proc attribute(attr: NimNode): NimNode =
  newColonExpr(
    newStrLitNode($attr[0]),
    if attr[1].kind in [nnkStrLit, nnkTripleStrLit]:
      newCall("fmt", attr[1])
    else:
      attr[1]
  )


proc addAttribute(node, key, value: NimNode) =
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


proc endsWithBuildHtml(statement: NimNode): bool =
  statement[^1].kind == nnkCall and $statement[^1][0] == "buildHtml"


proc replaceSelfComponent(statement, componentName: NimNode) =
  if statement.kind == nnkDotExpr:
    if statement[0].kind == nnkIdent and $statement[0] == "self":
      statement[0] = newDotExpr(ident("self"), componentName)
    return

  if statement.kind == nnkAsgn:
    if statement[0].kind == nnkDotExpr and $statement[0][0] == "self":
      statement[0] = newDotExpr(statement[0], ident("val"))
      statement[0][0][0] = newDotExpr(ident("self"), componentName)

    for idx, i in statement.pairs:
      if idx == 0:
        continue
      i.replaceSelfComponent(componentName)
  else:
    for idx, i in statement.pairs:
      if i.kind == nnkAsgn and i[0].kind == nnkDotExpr and $i[0][0] == "self":
        statement.insert(idx+1, newCall(newDotExpr(ident("self"), ident("reRender"))))
    for i in statement.children:
      i.replaceSelfComponent(componentName)


proc replaceSelfStateVal(statement: NimNode) =
  for idx, i in statement.pairs:
    if i.kind == nnkDotExpr:
      if $i[0] == "self":
        statement[idx] = newCall("get", newDotExpr(i[0], i[1]))
      continue
    if i.kind in RoutineNodes:
      continue
    i.replaceSelfStateVal()


proc pathParamsBoilerplate(node: NimNode, kind, regexVal: var string) =
  if node.kind == nnkIdent:
    kind = $node
  # regex type
  elif node.kind == nnkCallStrLit and $node[0] == "re":
    kind = "regex"
    regexVal = $node[1]
  else:
    let current = $node.toStrLit
    throwDefect(
      InvalidPathParamDefect,
      "Invalid path param type: " & current,
      lineInfoObj(node)
    )


proc buildHtmlProcedure*(root, body: NimNode, inComponent: bool = false,
                         componentName: NimNode = newEmptyNode(), inCycle: bool = false,
                         cycleTmpVar: string = "", cycleVars: seq[NimNode] = @[]): NimNode =
  ## Builds HTML
  let elementName = newStrLitNode(getTagName($root))
  result = newCall("initTag", elementName)

  for statement in body:
    if statement.kind == nnkCall:
      let
        tagName = newStrLitNode(getTagName($statement[0]))
        statementList = statement[^1]
      var attrs = newNimNode(nnkTableConstr)
      # tag(attr="value"):
      #   ...
      if statement.len-2 > 0 and statementList.kind == nnkStmtList:
        var builded = buildHtmlProcedure(tagName, statementList, inComponent, componentName, inCycle, cycleTmpVar, cycleVars)
        for attr in statement[1 .. statement.len-2]:
          builded.addAttribute(
            newStrLitNode($attr[0]),
            if attr[1].kind in [nnkStrLit, nnkTripleStrLit]:
              newCall("fmt", attr[1])
            else:
              attr[1]
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
        result.add(buildHtmlProcedure(tagName, statementList, inComponent, componentName, inCycle, cycleTmpVar, cycleVars))
    
    elif statement.kind == nnkCommand:
      # Component usage
      if $statement[0] == "component":
        let
          name =
            if statement[1].kind == nnkCall:
              statement[1][0]
            else:
              statement[1]
          componentName = fmt"comp{uniqueId}{uniqueId + 2}{uniqueId * 2}{uniqueId + 7}"
          objConstr = newCall(fmt"init{name}")
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
        objConstr.add(newNimNode(nnkExprEqExpr).add(
          ident(UniqueComponentId),
          stringId
        ))
        if statement[1].kind == nnkCall:
          for i in 1..<statement[1].len:
            objConstr.add(newNimNode(nnkExprEqExpr).add(
              statement[1][i][0], statement[1][i][1]
            ))
        result.add(newStmtList(
          newVarStmt(ident(componentNameTmp), objConstr),
          newVarStmt(
            ident(componentName),
            newCall(
              name,
              newCall("registerComponent", stringId, ident(componentNameTmp))
            )
          ),
          newAssignment(
            newDotExpr(ident(componentName), ident("slot")),
            buildHtmlProcedure(
              ident("div"), componentSlot, inComponent, ident(componentName), inCycle, cycleTmpVar, cycleVars
            ).add(newLit(true))
          ),
          newLetStmt(
            ident(componentData),
            newCall("render", ident(componentName))
          ),
          newCall(
            "addArgIter",
            ident(componentData),
            newCall("&", newStrLitNode("data-"), newDotExpr(ident(componentName), ident(UniqueComponentId)))
          ),
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident("emit"),
            newStrLitNode(fmt"window.addEventListener('beforeunload', `{componentData}`.`exited`);")
          )),
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident("emit"),
            newStrLitNode(fmt"window.addEventListener('pagehide', `{componentData}`.`pageHide`);")
          )),
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident("emit"),
            newStrLitNode(fmt"window.addEventListener('pageshow', `{componentData}`.`pageShow`);")
          )),
          ident(componentData)
        ))
    
    elif statement.kind in [nnkStrLit, nnkTripleStrLit]:
      # "Raw text"
      result.add(newCall("initTag", newCall("fmt", statement), newLit(true)))
    
    elif statement.kind == nnkAsgn:
      # Attributes
      result.addAttribute(statement[0], statement[1])
    
    # Events handling
    elif statement.kind == nnkPrefix and $statement[0] == "@":
      let
        event = $statement[1]
        evname = if event.startsWith("on"): event else: "on" & event
        args = newNimNode(nnkFormalParams).add(
          newEmptyNode()
        )
        procedure = newLambda(newStmtList(), args)
      
      if inComponent:
        statement[2].replaceSelfComponent(componentName)
        procedure.body = statement[2]
        args.add(newIdentDefs(ident("self"), ident("BaseComponent")))
        # Detect in component and in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & "}"
            registerEvent = fmt"registerEventScoped{uniqueId}{uniqueId+2}"
            callRegister = newCall(registerEvent)
          var procParams = @[ident("ComponentEventHandler")]
          for i in cycleVars:
            procParams.add(newIdentDefs(i, ident("any")))
            callRegister.add(i)
          result.addAttribute(
            newStrLitNode(evname),
            newCall(
              "fmt",
              newStrLitNode(
                "callComponentEventHandler('{self." & UniqueComponentId & "}', {" &
                fmt"{uniqueId}" & cycleVar & ")"
              )
            )
          )
          result.add(
            newStmtList(
              newProc(ident(registerEvent), procParams, procedure),
              newCall(
                "[]=",
                ident("componentEventHandlers"),
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
                "callComponentEventHandler('{self." & UniqueComponentId & "}', " & fmt"{uniqueId})"
              )
            )
          )
          result.add(newStmtList(
            newCall("once",
              newCall("[]=", ident("componentEventHandlers"), newIntLitNode(uniqueId), procedure)
            ), newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
          ))
        procedure.body.insert(0, newAssignment(ident("currentComponent"), newCall("fmt", newStrLitNode("{self.uniqCompId}"))))
        procedure.body.add(newAssignment(ident("currentComponent"), newStrLitNode("")))
      else:
        procedure.body = statement[2]
        # not in component but in cycle
        if inCycle:
          let
            cycleVar = " + " & cycleTmpVar  & "}"
            registerEvent = fmt"registerEventScoped{uniqueId}{uniqueId+2}"
            callRegister = newCall(registerEvent)
          var procParams = @[ident("AppEventHandler")]
          for i in cycleVars:
            procParams.add(newIdentDefs(i, ident("any")))
            callRegister.add(i)
          result.addAttribute(
            newStrLitNode(evname),
            newCall(
              "fmt",
              newStrLitNode("callEventHandler({" & fmt"{uniqueId}" & cycleVar & ")")
            )
          )
          result.add(
            newStmtList(
              newProc(ident(registerEvent), procParams, procedure),
              newCall(
                "[]=",
                ident("eventHandlers"),
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
            newStrLitNode(fmt"callEventHandler({uniqueId})")
          )
          result.add(newStmtList(
            newCall("once",
              newCall("[]=", ident("eventHandlers"), newIntLitNode(uniqueId), procedure)
            ), newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
          ))
      inc uniqueId
    
    elif statement.kind == nnkIdent:
      if $statement == "slot":
        # slot
        if not inComponent:
          throwDefect(
            ComponentSyntaxDefect,
            fmt"Slots can be used only in components!",
            lineInfoObj(statement)
          )
        result.add(newDotExpr(ident("self"), ident("slot")))
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
          ident("div"), statement[i][^1], inComponent, componentName, inCycle, cycleTmpVar, cycleVars
        ).add(newLit(true))
      if statement[^1].kind != nnkElse:
        statement.add(newNimNode(nnkElse).add(newNilLit()))
      result.add(statement)
    
    # for ... in ...:
    #   ...
    elif statement.kind == nnkForStmt:
      var
        unqn = fmt"tmpCycleIdx{uniqueId}"
        idents: seq[NimNode] = @[]
      # extract cycle variables
      for i in 0..statement.len-3:
        idents.add statement[i]
      inc uniqueId
      statement[^1] = newStmtList(
        buildHtmlProcedure(ident("tDiv"), statement[^1], inComponent, componentName, true, unqn, idents)
      )
      statement[^1].insert(0, newCall("inc", ident(unqn)))
      result.add(
        newCall(
          "initTag",
          newStrLitNode("div"),
          newStmtList(
            newVarStmt(ident(unqn), newLit(0)),
            newCall(
              "collect",
              ident("newSeq"),
              newStmtList(
                statement
              )
            ),
          ),
          newLit(true)
        )
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

{.pop.}


macro buildHtml*(root, html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## 
  ## Args:
  ## - `root`: root element. It's can be `tag`, tag or tTag
  ## - `html`: YAML-like structure.
  ## 
  ## Syntax support:
  ##   - attributes via exprEqExpr
  ##   
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          h1(class="myClass", align="center")
  ##          input(`type`="password", align="center")
  ##   
  ##   - nested tags
  ##   
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          tag:
  ##            tag1:
  ##              tag2:
  ##            tag1withattrs(attr="value")
  ##   
  ##   - if-elif-else expressions
  ## 
  ##     .. code-block:: nim
  ##        var
  ##          state = true
  ##          state2 = true
  ##        echo buildHtml(`div`):
  ##          if state:
  ##            "True!"
  ##          else:
  ##            "False("
  ##          if state2:
  ##            "State2 is true"
  ## 
  ##   - case-of statement:
  ## 
  ##     .. code-block:: nim
  ##        type X = enum:
  ##          xA,
  ##          xB,
  ##          xC
  ##        var x = xA
  ##        echo buildHtml(`div`):
  ##          case x:
  ##          of xA:
  ##            "xA"
  ##          of xB:
  ##            "xB"
  ##          else:
  ##            "Other
  ##   
  ##   - for statements
  ## 
  ##     .. code-block:: nim
  ##        var state = @["h1", "h2", "input"]
  ##        echo buildHtml(`div`):
  ##          for i in state:
  ##            i
  ## 
  ##   - components
  ## 
  ##     .. code-block:: nim
  ##        component MyComponent
  ##        component MyComponent(field1 = value1, field2 = value2)
  ## 
  buildHtmlProcedure(root, html)


macro buildHtml*(html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## This macro doesn't generate Root tag
  ## 
  ## Args:
  ## - `html`: YAML-like structure.
  ## 
  result = buildHtmlProcedure(ident("tDiv"), html)
  if result[^1].kind == nnkCall and $result[^1][0] == "@":
    result.add(newLit(true))


macro buildComponentHtml*(componentName, html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## This macro doesn't generate Root tag
  ## 
  ## Args:
  ## - `html`: YAML-like structure.
  ## 
  result = buildHtmlProcedure(ident("tDiv"), html, true, componentName)


macro routes*(app: App, body: untyped): untyped =
  ## Provides JS router for Single page application
  ## 
  ## ## Usage:
  ## 
  ## .. code-block:: nim
  ##    app.routes:
  ##      "/":
  ##        "Hello, world!"
  ##      
  ##      "/user{id:int}":
  ##        "User {id}"
  ## 
  ##      "/pattern{rePattern:/\d+\.\d+\+\d+\S[a-z]/}":
  ##        {rePattern}
  ## 
  ##      "/get{file:path}":
  ##        "path to file is '{file}'"
  ## 
  let
    iPath = ident("path")
    iHtml = ident("html")
    iRouter = ident("callRouter")
    router = newProc(
      postfix(iRouter, "*"),
      [newEmptyNode(), newIdentDefs(ident("force"), ident("bool"), newLit(false))]
    )
    onDOMContentLoaded = newProc(
      ident("onDOMContentLoaded"),
      [newEmptyNode(), newIdentDefs(ident("ev"), ident("Event"))]
    )
    ifStmt = newNimNode(nnkIfStmt)

  # On DOM Content Loaded
  onDOMContentLoaded.body = newStmtList(newCall(iRouter))
  router.body = newStmtList()

  # Router
  router.body.add(
    newLetStmt(
      ident("elem"),
      newCall("getElementById", ident("document"), newDotExpr(ident("app"), ident("appId")))
    ),
    newLetStmt(
      ident("path"),
      newCall(
        "strip",
        newCall("$", newDotExpr(newDotExpr(ident("window"), ident("location")), ident("hash"))),
        newLit(true),
        newLit(false),
        newNimNode(nnkCurly).add(newLit('#'))
      )
    ),
    newNimNode(nnkVarSection).add(newIdentDefs(iHtml, ident("TagRef"), newNilLit())),
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      newCall("and",
        newCall("not", ident("force")),
        newCall(">", newCall("len", ident("currentComponent")), newLit(0)),
      ),
      newStmtList(
        newCall(
          "reRender",
          newNimNode(nnkBracketExpr).add(
            ident("components"),
            ident("currentComponent")
          )
        ),
        newCall("echo", ident("currentComponent")),
        newNimNode(nnkReturnStmt).add(newEmptyNode())
      )
    ))
  )

  # Find mounts
  body.findAndReplaceMount()

  for key in sugarRoutes.keys():
    if sugarRoutes[key].httpMethod.toLower() in ["build", "page"]:
      body.add(newCall(newStrLitNode(key), sugarRoutes[key].body))
  
  for statement in body:
    if statement.kind in [nnkCommand, nnkCall]:
      if statement.len == 2 and statement[0].kind == nnkStrLit:
        let exported = exportRouteArgs(
          iPath,
          statement[0],
          statement[1]
        )
        # Route contains params
        if exported.len > 0:
          for i in 0..<statement[1].len:
            exported[^1].del(exported[^1].len-1)
          exported[^1] = newStmtList(
            exported[^1],
            newAssignment(
              iHtml,
              if statement[1].endsWithBuildHtml:
                statement[1]
              else:
                newCall("buildHtml", statement[1])
            )
          )
          ifStmt.add(exported)
        # Route doesn't contains any params
        else:
          ifStmt.add(newNimNode(nnkElifBranch).add(
            newCall("==", iPath, statement[0]),
            newAssignment(
              iHtml,
              if statement[1].endsWithBuildHtml:
                statement[1]
              else:
                newCall("buildHtml", statement[1])
            )
          ))
      elif statement[1].kind == nnkStmtList and statement[0].kind == nnkIdent:
        case $statement[0]
        of "notfound":
          if statement[1].endsWithBuildHtml:
            router.body.add(
              newAssignment(iHtml, statement[1])
            )
          else:
            router.body.add(
              newAssignment(iHtml, newCall("buildHtml", statement[1]))
            )
  
  if ifStmt.len > 0:
    router.body.add(ifStmt)
  
  router.body.add(
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      newCall("not", newCall("isNil", iHtml)),
      newStmtList(
        newAssignment(
          newDotExpr(ident("elem"), ident("innerHTML")),
          newCall("$", iHtml)
        )
      )
    ))
  )

  newStmtList(
    router,
    newAssignment(newDotExpr(ident("app"), ident("router")), router.name),
    onDOMContentLoaded
  )


macro appRoutes*(name: string, body: untyped): untyped =
  ## Registers a new Single page application, creates routing for it and starts SPA.
  ##
  ## ## Basic Usage:
  ## 
  ## .. code-block::nim
  ##    appRoutes("app"):
  ##      "/":
  ##        "Hello, world!"
  ## 
  newStmtList(
    newVarStmt(ident("app"), newCall("registerApp", name)),
    newCall("routes", ident("app"), body),
    newCall("start", ident("app"))
  )


macro component*(name, body: untyped): untyped =
  ## Register a new component.
  ## 
  ## ## Basic Usage:
  ## 
  ## .. code-block::nim
  ##    component Component:
  ##      requiredField: int
  ##      optionalField: int = 100
  ##      
  ##      `template`:
  ##        tDiv:
  ##          "requiredField is {self.requiredField}"
  ##        tDiv:
  ##          "optionalField is {self.optionalField}
  ##       
  ##      `script`:
  ##        echo self.requiredField
  ##        echo self.optionalField
  ##      
  ##      `style`:
  ##        """
  ##        div {
  ##          width: {self.requiredField}px;
  ##          height: {self.optionalField}px;
  ##        }
  ##        """
  ## 
  let
    name = $name
    nameObj = $name & "Obj"
    params = newNimNode(nnkRecList)
    initParams = newNimNode(nnkFormalParams)
    initProc = newProc(postfix(ident(fmt"init{name}"), "*"))
    initObjConstr = newNimNode(nnkObjConstr).add(
      ident(name), newColonExpr(ident(UniqueComponentId), ident(UniqueComponentId))
    )
    beforeStmtList = newStmtList()
    afterStmtList = newStmtList()
    reRenderProc = newProc(
      postfix(ident("reRender"), "*"),
      [newEmptyNode(), newIdentDefs(ident("self"), ident(name))],
      newStmtList(
        newLetStmt(
          ident("tmpData"),
          newCall(
            "&",
            newCall("&", newStrLitNode("[data-"), (newDotExpr(ident("self"), ident(UniqueComponentId)))),
            newStrLitNode("]")
          )
        ),
        newLetStmt(
          ident("compTmpData"),
          newCall(newDotExpr(ident("self"), ident("render")))
        ),
        newCall(
          "addArgIter",
          ident("compTmpData"),
          newCall("&", newStrLitNode("data-"), newDotExpr(ident("self"), ident(UniqueComponentId)))
        ),
        newAssignment(
          newDotExpr(
            newCall("querySelector", ident("document"), ident("tmpData")),
            ident("outerHTML")
          ),
          newCall("cstring", newCall("$", ident("compTmpData")))
        )
      ),
      nnkMethodDef
    )
  
  var
    templateStmtList = newStmtList()
    scriptStmtList = newStmtList()
    styleStmtList = newStmtList()
    arguments = @[newEmptyNode(), newIdentDefs(ident("self"), ident("BaseComponent"))]
    usedLifeCycles = {
      "created": false,
      "updated": false,
      "beforeUpdated": false,
      "exited": false,
      "pageShow": false,
      "pageHide": false,
    }.newTable()
  
  initParams.add(
    ident(name),
    newIdentDefs(ident(UniqueComponentId), bindSym("string"))
  )
  
  for s in body.children:
    if s.kind == nnkCall:
      if s[0].kind == nnkIdent and s.len == 2 and s[^1].kind == nnkStmtList and s[^1].len == 1:
        # Extract default value and field type
        let (fieldType, defaultValue) =
          if s[^1][0].kind == nnkIdent:
            (s[^1][0], newEmptyNode())
          else:  # assignment statement
            (s[^1][0][0], s[^1][0][1])
        params.add(newNimNode(nnkIdentDefs).add(
          postfix(s[0], "*"),
          newCall(
            bindSym("[]", brForceOpen), ident("State"), fieldType
          ),
          newEmptyNode()
        ))
        initParams.add(newNimNode(nnkIdentDefs).add(
          s[0], fieldType, defaultValue
        ))
        initObjConstr.add(newColonExpr(s[0], newCall("remember", s[0])))
    
      elif s[0].kind == nnkAccQuoted:
        case $s[0]
        of "template":
          # Component template
          templateStmtList = newStmtList(
            newAssignment(ident("currentComponent"), newDotExpr(ident("self"), ident(UniqueComponentId))),
            newCall("script", ident("self")),
            beforeStmtList,
            newAssignment(
              ident("result"),
              newCall(
                "buildComponentHtml",
                ident(name),
                s[1].add(newCall(
                  "style", newStmtList(newStrLitNode("{self.style()}"))
                ))
              )
            ),
            afterStmtList,
            newAssignment(ident("currentComponent"), newStrLitNode(""))
          )
        of "style":
          # Component styles
          let str = ($s[1][0]).replace(
            re"^([\S ]+?) *\{(?im)", "$1[data-{self.uniqCompId}]{{"
          ).replace(re"(^ *|\{ *|\n *)\}(?im)", "$1}}")
          styleStmtList = newStmtList(
            newAssignment(
              ident("result"),
              newCall("fmt", newStrLitNode(str))
            )
          )
        of "script":
          # Component main script
          s[1].replaceSelfStateVal()
          if scriptStmtList.len == 0:
            scriptStmtList = s[1]
          else:
            for child in s[1].children:
              scriptStmtList.add(child)
        else:
          let structure = $s[0]
          throwDefect(
            ComponentSyntaxDefect,
            fmt"undefined component structure ({structure}).",
            lineInfoObj(s)
          )
      
    elif s.kind == nnkPrefix:
      if s[0].kind == nnkIdent and $s[0] == "@" and s.len == 3 and s[1].kind == nnkIdent:
        # Component life cycles
        let key = $s[1]
        if usedLifeCycles.hasKey(key) and not usedLifeCycles[key]:
          scriptStmtList.insert(0, newAssignment(
            newDotExpr(ident("self"), ident(key)),
            newLambda(s[2], arguments)
          ))
          usedLifeCycles[key] = true
        elif not usedLifeCycles.hasKey(key):
          throwDefect(
            ComponentSyntaxDefect,
            fmt"Wrong component event ({key})",
            lineInfoObj(s)
          )
  
  for key in usedLifeCycles.keys:
    if not usedLifeCycles[key]:
      scriptStmtList.insert(0, newAssignment(
        newDotExpr(ident("self"), ident(key)),
        newLambda(newStmtList(discardStmt), arguments)
      ))
  
  initProc.params = initParams
  initProc.body = initObjConstr

  # Life cycles
  beforeStmtList.add(
    # Is created
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      newCall("==", newDotExpr(ident("self"), ident("isCreated")), newLit(false)),
      newStmtList(
        newCall(newDotExpr(ident("self"), ident("created")), ident("self")),
        newAssignment(
          newDotExpr(ident("self"), ident("isCreated")),
          newLit(true)
        )
      )
    ))
  ).add(
    # beforeUpdated
    newCall(newDotExpr(ident("self"), ident("beforeUpdated")), ident("self"))
  )
  # updated
  afterStmtList.add(
    newCall(newDotExpr(ident("self"), ident("updated")), ident("self"))
  )

  result = newStmtList(
    newNimNode(nnkTypeSection).add(
      newNimNode(nnkTypeDef).add(
        postfix(ident(nameObj), "*"),  # name
        newEmptyNode(),
        newNimNode(nnkObjectTy).add(
          newEmptyNode(),  # no pragma
          newNimNode(nnkOfInherit).add(ident("BaseComponentObj")),
          params
        )
      ),
      newNimNode(nnkTypeDef).add(
        postfix(ident(name), "*"),  # name
        newEmptyNode(),
        newNimNode(nnkRefTy).add(ident(nameObj))
      )
    ),
    initProc,
    reRenderProc,
    newProc(
      ident("script"),
      [
        newEmptyNode(),
        newIdentDefs(ident("self"), ident(name))
      ],
      scriptStmtList
    ),
    newProc(
      ident("style"),
      [
        ident("string"),
        newIdentDefs(ident("self"), ident(name))
      ],
      styleStmtList
    ),
    newProc(
      postfix(ident("render"), "*"),
      [
        ident("TagRef"),
        newIdentDefs(ident("self"), ident(name))
      ],
      templateStmtList,
      nnkMethodDef
    ),
  )


macro pathParams*(body: untyped): untyped =
  ## `pathParams` provides path params assignment ✨.
  ## 
  ## Simple usage:
  ## 
  ## .. code-block:: nim
  ##    pathParams:
  ##      # means that `arg` of type `int` is optional mutable param with default value `5`
  ##      arg? int[m] = 5
  ##      # means that `arg1` of type `string` is optional mutable param with default value `"Hello"`
  ##      arg1[m] = "Hello"
  ##      # means that `arg2` of type `string` is immutable regex param
  ##      arg2 re"\d+u"
  ##      # means that `arg3` of type `float` is mutable param
  ##      arg3 float[m]
  ##      # means that `arg4` of type `int` is optional mutable param with default value `10`
  ##      arg4:
  ##        type int
  ##        mutable
  ##        optional
  ##        default = 10
  ## 
  for statement in body:
    var
      name = ""
      kind = "string"
      regexVal = ""
      isMutable = false
      isOptional = false
      defaultVal = ""
    
    # Just ident
    if statement.kind == nnkIdent:
      name = $statement
    
    # Assignment
    # argument? type[m] = val
    elif statement.kind == nnkAsgn:
      if statement[0].kind == nnkInfix and $statement[0][0] == "?":
        # name
        name = $statement[0][1]
        # type
        if statement[0].len == 3:
          # type[m]
          if statement[0][2].kind == nnkBracketExpr and $statement[0][2][1] == "m":
            isMutable = true
            pathParamsBoilerplate(statement[0][2][0], kind, regexVal)
          # type
          else:
            pathParamsBoilerplate(statement[0][2], kind, regexVal)
            kind = $statement[0][2]
        # default val
        if statement[1].kind in AtomicNodes:
          defaultVal = $statement[1].toStrLit
          isOptional = true
        else:
          let current = $statement[1].toStrLit
          throwDefect(
            InvalidPathParamDefect,
            "Invalid path param default value (should be atomic const types)" & current,
            lineInfoObj(statement[1])
          )
      # arg[m]
      elif statement[0].kind == nnkBracketExpr and $statement[0][1] == "m":
        isMutable = true
        name = $statement[0][0]
        # default val
        if statement[1].kind in AtomicNodes:
          defaultVal = $statement[1].toStrLit
          isOptional = true
        else:
          let current = $statement[1].toStrLit
          throwDefect(
            InvalidPathParamDefect,
            "Invalid path param default value (should be atomic const types)" & current,
            lineInfoObj(statement[1])
          )
    
    # infix
    # argument? type[m]
    elif statement.kind == nnkInfix and $statement[0] == "?":
      # name
      name = $statement[1]
      isOptional = true
      # type
      if statement.len == 3:
        # type[m]
        if statement[2].kind == nnkBracketExpr and $statement[2][1] == "m":
          pathParamsBoilerplate(statement[2][0], kind, regexVal)
        # type
        else:
          pathParamsBoilerplate(statement[2], kind, regexVal)
    
    # command
    elif statement.kind in [nnkCall, nnkCommand]:
      name = $statement[0]
      # type[m]
      if statement[1].kind == nnkBracketExpr and $statement[1][1] == "m":
        isMutable = true
        pathParamsBoilerplate(statement[1][0], kind, regexVal)
      # type
      else:
        pathParamsBoilerplate(statement[1], kind, regexVal)
      # stmt list
      if statement[^1].kind == nnkStmtList:
        for child in statement[^1].children:
          case child.kind
          # optional, mutable etc.
          of nnkIdent:
            let childStr = $child
            if childStr == "optional":
              isOptional = true
            elif childStr == "mutable":
              isMutable = true
            else:
              let current = childStr
              throwDefect(
                InvalidPathParamDefect,
                "Invalid flag for path param: " & childStr,
                lineInfoObj(child)
              )
          of nnkTypeSection:
            # param type
            if child[0].kind == nnkTypeDef and child[0][0].kind == nnkIdent:
              kind = $child[0][0]
          of nnkAsgn:
            let childStr = $child[0]
            # default val
            if childStr == "default":
              if child[1].kind in AtomicNodes:
                defaultVal = $child[1].toStrLit
                isOptional = true
          else:
            let
              current = $child.toStrLit
              allStatement = ($statement[^1].toStrLit).replace(current, "> " & current)
            throwDefect(
              InvalidPathParamDefect,
              "invalid path param assignment:" & allStatement,
              lineInfoObj(child)
            )
    
    if name.len > 0:
      var res = "{" & name
      if isOptional:
        res &= "?"
      if kind != "regex":
        res &= ":" & kind
      else:
        res &= ":/" & regexVal & "/"
      if isMutable:
        res &= "[m]"
      if defaultVal.len > 0:
        res &= "=" & defaultVal
      declaredPathParams[name] = res & "}"
