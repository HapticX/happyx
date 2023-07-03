## # Renderer ✨
## 
## Provides a single-page application (SPA) renderer with reactivity features.
## It likely contains functions or classes that allow developers to
## dynamically update the content of a web page without reloading the entire page.
## 
## 
## ## Moving Between Routes 🎈
## To move to other location just use `route("/path")`
## 
## ## Usage 🔨
## 
## .. code-block:: nim
##    import happyx
##    
##    appRoutes("app"):
##      "/":
##        tDiv:
##          "Hello, world!"
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
  ./translatable,
  ../core/[exceptions, constants],
  ../private/[macro_utils],
  ../routing/[routing, mounting],
  ../sugar/[sgr, style, js]


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
  UniqueComponentId* = "uniqCompId"


when defined(js):
  buildJs:
    function callEventHandler(idx):
      nim:
        var idx: int
      ~idx = idx
      nim:
        eventHandlers[idx]()
    function callComponentEventHandler(componentId, idx):
      nim:
        var
          callbackIdx: int
          componentId: cstring
      ~callbackIdx = idx
      ~componentId = componentId
      nim:
        componentEventHandlers[callbackIdx](components[componentId])


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


when defined(js):
  proc renderVdom*(app: App, tag: TagRef) =
    ## Rerender DOM with VDOM
    # compile with `-d:oldRenderer` to work with old renderer
    when enableOldRenderer:
      document.getElementById(app.appId).innerHTML = $tag
    else:
      let elem = document.getElementById(app.appId)
      var
        realDom = elem.Node
        virtualDom = tag.toDom().n
      # echo virtualDom.innerHTML
      # echo realDom.innerHTML
      realDom.innerHTML = virtualDom.innerHTML
      # compareEdit(realDom, virtualDom)
else:
  proc renderVdom*(app: App, tag: TagRef) =
    ## Rerender DOM with VDOM
    discard


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
  if window.location.hash.len == 0:
    route("/")
  else:
    {.emit : "if(window.location.hash[0]=='#'){`route`(window.location.hash.substr(1));}else{`route`(window.location.hash);}".}


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


proc attribute(attr: NimNode): NimNode =
  ## Converts `nnkExprEqExpr` to `nnkColonExpr`
  newColonExpr(
    newStrLitNode($attr[0]),
    formatNode(attr[1])
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
      statement[0] = newDotExpr(ident"self", componentName)
    return

  if statement.kind == nnkAsgn:
    if statement[0].kind == nnkDotExpr and $statement[0][0] == "self":
      statement[0] = newDotExpr(statement[0], ident"val")
      statement[0][0][0] = newDotExpr(ident"self", componentName)

    for idx, i in statement.pairs:
      if idx == 0:
        continue
      i.replaceSelfComponent(componentName)
  else:
    for idx, i in statement.pairs:
      if i.kind == nnkAsgn and i[0].kind == nnkDotExpr and $i[0][0] == "self":
        statement.insert(idx+1, newCall(newDotExpr(ident"self", ident"reRender")))
    for i in statement.children:
      i.replaceSelfComponent(componentName)


proc buildHtmlProcedure*(root, body: NimNode, inComponent: bool = false,
                         componentName: NimNode = newEmptyNode(), inCycle: bool = false,
                         cycleTmpVar: string = "", cycleVars: seq[NimNode] = @[]): NimNode =
  ## Builds HTML
  let elementName = newStrLitNode(getTagName($root))
  result = newCall("initTag", elementName)

  for statement in body:
    if statement.kind == nnkCall and statement[0] == ident"nim" and statement.len == 2 and statement[1].kind == nnkStmtList:
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

    elif statement.kind == nnkCall:
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
              ident"div", componentSlot, inComponent, ident(componentName), inCycle, cycleTmpVar, cycleVars
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
        ))
    
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
        args.add(newIdentDefs(ident"self", ident"BaseComponent"))
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
                fmt"{uniqueId}" & cycleVar & ")"
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
                "callComponentEventHandler('{self." & UniqueComponentId & "}', " & fmt"{uniqueId})"
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
        procedure.body = statement[2]
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
              newStrLitNode("callEventHandler({" & fmt"{uniqueId}" & cycleVar & ")")
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
            newStrLitNode(fmt"callEventHandler({uniqueId})")
          )
          result.add(newStmtList(
            newCall("once",
              newCall("[]=", ident"eventHandlers", newIntLitNode(uniqueId), procedure)
            ), newCall("initTag", newStrLitNode("div"), newCall("@", newNimNode(nnkBracket)), newLit(true))
          ))
      inc uniqueId
    
    elif statement.kind == nnkIdent:
      if $statement == "slot":
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
          ident"div", statement[i][^1], inComponent, componentName, inCycle, cycleTmpVar, cycleVars
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
              buildHtmlProcedure(ident"div", body, inComponent, componentName, inCycle, cycleTmpVar, cycleVars)
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
        idents.add statement[i]
      inc uniqueId
      statement[^1] = newStmtList(
        buildHtmlProcedure(ident"div", statement[^1], inComponent, componentName, true, unqn, idents)
      )
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
  ##   - for statement
  ## 
  ##     .. code-block:: nim
  ##        var state = @["h1", "h2", "input"]
  ##        echo buildHtml(`div`):
  ##          for i in state:
  ##            i
  ## 
  ##   - while statement
  ## 
  ##     .. code-block:: nim
  ##        var state = 0
  ##        echo buildHtml(`div`):
  ##          while state < 10:
  ##            nim:
  ##              inc state
  ##            "{state}th"
  ## 
  ##   - rawHtml statement
  ## 
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          rawHtml:  """
  ##            <div>
  ##              Hello, world!
  ##            </div>
  ##            """
  ## 
  ##   - script statement
  ## 
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          tScript(...): """
  ##            console.log("Hello, world!");
  ##            """
  ## 
  ##   - component usage
  ## 
  ##     .. code-block:: nim
  ##        component MyComponent
  ##        component MyComponent(field1 = value1, field2 = value2)
  ##        component MyComponent:
  ##          slotHtml
  ## 
  buildHtmlProcedure(root, html)


macro buildHtml*(html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## This macro doesn't generate Root tag
  ## 
  ## Args:
  ## - `html`: YAML-like structure.
  ## 
  result = buildHtmlProcedure(ident"tDiv", html)
  if result[^1].kind == nnkCall and $result[^1][0] == "@":
    result.add(newLit(true))


macro buildComponentHtml*(componentName, html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## This macro doesn't generate Root tag
  ## 
  ## Args:
  ## - `html`: YAML-like structure.
  ## 
  result = buildHtmlProcedure(ident"tDiv", html, true, componentName)


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
    iPath = ident"path"
    iHtml = ident"html"
    iRouter = ident"callRouter"
    router = newProc(
      postfix(iRouter, "*"),
      [newEmptyNode(), newIdentDefs(ident"force", ident"bool", newLit(false))]
    )
    onDOMContentLoaded = newProc(
      ident"onDOMContentLoaded",
      [newEmptyNode(), newIdentDefs(ident"ev", ident"Event")]
    )
    ifStmt = newNimNode(nnkIfStmt)
  var finalize = newStmtList()

  # On DOM Content Loaded
  onDOMContentLoaded.body = newStmtList(newCall(iRouter))
  router.body = newStmtList()

  # Router
  router.body.add(
    newLetStmt(
      ident"elem",
      newCall("getElementById", ident"document", newDotExpr(ident"app", ident"appId"))
    ),
    newLetStmt(
      ident"path",
      newCall(
        "strip",
        newCall("$", newDotExpr(newDotExpr(ident"window", ident"location"), ident"hash")),
        newLit(true),
        newLit(false),
        newNimNode(nnkCurly).add(newLit('#'))
      )
    ),
    newNimNode(nnkVarSection).add(newIdentDefs(iHtml, ident"TagRef", newNilLit())),
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      newCall("and",
        newCall("not", ident"force"),
        newCall(">", newCall("len", ident"currentComponent"), newLit(0)),
      ),
      newStmtList(
        newCall(
          "reRender",
          newNimNode(nnkBracketExpr).add(
            ident"components",
            ident"currentComponent"
          )
        ),
        newCall("echo", ident"currentComponent"),
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
        of "finalize":
          finalize = statement[1]
        of "notfound":
          if statement[1].endsWithBuildHtml:
            router.body.add(
              newAssignment(iHtml, statement[1])
            )
          else:
            router.body.add(
              newAssignment(iHtml, newCall("buildHtml", statement[1]))
            )
      elif statement[0].kind != nnkIdent and $statement[0] != "mount":
        throwDefect(
          HpxAppRouteDefect,
          "Unknown statement for Single Page Application routes ",
          lineInfoObj(statement)
        )
  
  if ifStmt.len > 0:
    router.body.add(ifStmt)
  
  router.body.add(
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      newCall("not", newCall("isNil", iHtml)),
      newStmtList(
        newCall("renderVdom", ident"application", iHtml)
      )
    ))
  )

  newStmtList(
    router,
    newAssignment(newDotExpr(ident"app", ident"router"), router.name),
    onDOMContentLoaded,
    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
      ident"emit",
      newStrLitNode(
        "window.addEventListener('beforeunload', (e) => {"
      )
    )),
    finalize,
    newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
      ident"emit",
      newStrLitNode(
        "});"
      )
    ))
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
    newVarStmt(ident"app", newCall("registerApp", name)),
    translatesStatement,
    newCall("routes", ident"app", body),
    newCall("start", ident"app")
  )
