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


when defined(js):
  type
    AppEventHandler* = proc(ev: Event = nil): void
    ComponentEventHandler* = proc(self: BaseComponent, ev: Event = nil): void
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
else:
  type
    AppEventHandler* = proc(ev: int = 0): void
    ComponentEventHandler* = proc(self: BaseComponent, ev: int = 0): void
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
  application*: App = nil  ## global application variable
  eventHandlers* = newTable[int, AppEventHandler]()
  componentEventHandlers* = newTable[int, ComponentEventHandler]()
  components* = newTable[cstring, BaseComponent]()
  currentComponent* = ""  ## Current component unique ID
  currentRoute*: cstring = "/"  ## Current route path


when defined(js):
  buildJs:
    function callEventHandler(idx, event):
      nim:
        var
          idx: int
          ev: Event
      ~idx = idx
      ~ev = event
      nim:
        eventHandlers[idx](ev)
    function callComponentEventHandler(componentId, idx, event):
      nim:
        var
          callbackIdx: int
          componentId: cstring
          evComponent: Event
      ~callbackIdx = idx
      ~componentId = componentId
      ~evComponent = event
      nim:
        componentEventHandlers[callbackIdx](components[componentId], evComponent)
  
macro elem*(name: untyped): untyped =
  ## `elem` macro is just shortcut for
  ## 
  ## .. code-block::nim
  ##    block:
  ##      var res: Element
  ##      {.emit: "`res` = document.getElementById('name')".}
  ##      res
  ## 
  ## ⚠ Works only on JS backend ⚠
  ## 
  let nameStr = $name
  when defined(js):
    newStmtList(
      newNimNode(nnkVarSection).add(newIdentDefs(
        ident"res", ident"Element"
      )),
      newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newStrLitNode(fmt"`res` = document.getElementById('{nameStr}');")
      )),
      ident"res"
    )


{.push inline.}

proc route*(path: cstring) =
  ## Change current page to `path` and rerender
  when defined(js):
    {.emit: "window.history.pushState(null, null, '#' + `path`);" .}
    let force = currentRoute != path
    currentRoute = path
    application.router(force)


proc registerApp*(appId: cstring = "app"): App {. discardable .} =
  ## Creates a new Single Page Application
  application = App(appId: appId)
  application


proc registerComponent*(name: cstring, component: BaseComponent): BaseComponent =
  ## Register a new component.
  ## 
  ## Don't use it because it used in `component` macro.
  ## 
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
  var h = html
  h.replaceSelfComponent(componentName)
  result = buildHtmlProcedure(ident"tDiv", h, true, componentName)
  if result[^1].kind == nnkCall and $result[^1][0] == "@":
    result.add(newLit(true))


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
  ## Automatically creates `app` variable
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
