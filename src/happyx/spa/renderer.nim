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
  std/macros,
  std/htmlgen,
  std/strtabs,
  std/strutils,
  std/strformat,
  std/tables,
  std/macrocache,
  ./tag,
  ../core/[exceptions, constants],
  ../private/[macro_utils],
  ../sugar/[sgr, js],
  ../routing/[mounting, decorators]

when enableDebug:
  import std/logging
  export logging

when enableAppRouting:
  import ../routing/routing


when defined(js):
  import
    dom,
    jsconsole
  export
    dom,
    jsconsole

export
  strformat,
  htmlgen,
  strtabs,
  strutils,
  tables,
  tag

{.experimental: "codeReordering".}

when defined(js):
  type
    AppEventHandler* = proc(): void
    App* = ref object
      appId*: cstring
      router*: proc(force: bool = false)
  when enableDefaultComponents:
    type
      ComponentEventHandler* = proc(self: BaseComponent, ev: Event = nil): void
      BaseComponent* = ref BaseComponentObj
      BaseComponentObj* {.inheritable.} = object
        uniqCompId*: string
        isCreated*: bool
        slot*: proc(
          scopeSelf: BaseComponent, inComponent: bool, compName: string,
          inCycle: bool, cycleCounter: var int, compCounter: string
        ): TagRef
        slotData*: TagRef
        created*: ComponentEventHandler  ## Calls before first rendering
        exited*: ComponentEventHandler  ## Calls after last rendering
        rendered*: ComponentEventHandler  ## Calls after every rendering
        pageHide*: ComponentEventHandler  ## Calls after every rendering
        pageShow*: ComponentEventHandler  ## Calls after every rendering
        beforeUpdated*: ComponentEventHandler  ## Calls before every rendering
        updated*: ComponentEventHandler  ## Calls after every DOM rendering
else:
  import json

  type
    AppEventHandler* = proc(ev: JsonNode = newJObject()): void
    App* = ref object
      appId*: cstring
      router*: proc(force: bool = false)
  when enableDefaultComponents:
    type
      ComponentEventHandler* = proc(self: BaseComponent, ev: JsonNode = newJObject()): void
      BaseComponent* = ref BaseComponentObj
      BaseComponentObj* {.inheritable.} = object
        uniqCompId*: string
        isCreated*: bool
        slot*: proc(
          scopeSelf: BaseComponent, inComponent: bool, compName: string,
          inCycle: bool, cycleCounter: var int, compCounter: string
        ): TagRef
        slotData*: TagRef
        created*: ComponentEventHandler  ## Calls before first rendering
        exited*: ComponentEventHandler  ## Calls after last rendering
        rendered*: ComponentEventHandler  ## Calls after every rendering
        pageHide*: ComponentEventHandler  ## Calls after every rendering
        pageShow*: ComponentEventHandler  ## Calls after every rendering
        beforeUpdated*: ComponentEventHandler  ## Calls before every rendering
        updated*: ComponentEventHandler  ## Calls after every DOM rendering
  var eventHandlers* = newTable[int, AppEventHandler]()


# Global variables
var
  rendererHandlers* = newSeq[tuple[key: string, p: AppEventHandler]]()
  application*: App = nil  ## global application variable
  currentRoute*: cstring = "/"  ## Current route path
  scopedCycleCounter*: int = 0
when enableLiveViews and not defined(js):
  var liveviewRoutes* = newTable[string, proc(): TagRef]()
  var components* = newTable[string, BaseComponent]()
when enableDefaultComponents:
  var
    componentEventHandlers* = newTable[int, ComponentEventHandler]()
    currentComponent* = ""  ## Current component unique ID
    currentComponentsList*: seq[BaseComponent] = @[]
    createdComponentsList*: seq[BaseComponent] = @[]

  when defined(js):
    var components* = newTable[cstring, BaseComponent]()
  else:
    var
      requestResult* = newTable[string, string]()
      componentsResult* = newTable[string, string]()


when defined(js):
  const uniqueMacroIndex = CacheCounter"uniqueMacroIndex"
macro rf*(name: untyped): untyped =
  ## `rf` macro is just shortcut for
  ## 
  ## .. code-block::nim
  ##    block:
  ##      var res: Element
  ##      {.emit: "`res` = document.getElementById('name')".}
  ##      res
  ## 
  ## ⚠ Works only on JS backend ⚠
  ## 
  when defined(js):
    inc uniqueMacroIndex
    let
      nameStr = $name
      uniqName = fmt"_res{uniqueMacroIndex.value}"
    result = newStmtList(
      newNimNode(nnkVarSection).add(newIdentDefs(
        ident(uniqName), ident"Element"
      )),
      newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit(fmt"`{uniqName}` = document.getElementById('{nameStr}');")
      )),
      ident(uniqName)
    )


{.push inline.}

when defined(js):
  proc route*(path: cstring) {.exportc: "rt".} =
    ## Change current page to `path` and rerender
    when enableHistoryApi:
      {.emit: """
      window.history.pushState({previous: window.location.pathname}, '', `path`);
      """ .}
    else:
      {.emit: """
      window.history.pushState({previous: window.location.href}, '', '#' + `path`);
      """ .}
    let force = currentRoute != path
    echo force, ", ", currentRoute, ", ", path
    currentRoute = path
    application.router(force)
    if force:
      window.scrollTo(0, 0)
  proc back*() {.exportc: "bck".} =
    ## Just calls [window.history.back procedure](https://nim-lang.org/docs/dom.html#back%2CHistory)
    window.history.back()
  proc forward*() {.exportc: "frwrd".} =
    ## Just calls [window.history.forward procedure](https://nim-lang.org/docs/dom.html#back%2CHistory)
    window.history.forward()
else:
  proc route*(host, path: string) =
    requestResult[host] = "route:" & path
  proc injectJs*(host, script: string) =
    requestResult[host] = "script:" & fmt"<script>{script}</script>"
  proc route*(comp: BaseComponent, path: string) =
    componentsResult[comp.uniqCompId] = "route:" & path
  proc js*(comp: BaseComponent, script: string) =
    componentsResult[comp.uniqCompId] = "script:" & fmt"<script>{script}</script>"
  proc rerender*(hostname, urlPath: string) =
    requestResult[hostname] = "rerender:" & liveviewRoutes[urlPath]().children[1].ugly()
  proc bck*(hostname, urlPath: string) =
    requestResult[hostname] = "bck"
  proc frwrd*(hostname, urlPath: string) =
    requestResult[hostname] = "frwrd"


proc registerApp*(appId: cstring = "app"): App {. discardable .} =
  ## Creates a new Single Page Application
  ## 
  ## ⚠ This is `Low-level API` ⚠
  ## 
  ## use `appRoutes proc<#appRoutes.m,string>`_ instead of this
  ## because this procedure calls automatically.
  ## 
  application = App(appId: appId)
  application


when enableDefaultComponents:
  when defined(js):
    proc registerComponent*(name: cstring, component: BaseComponent): BaseComponent {.exportc: "rgcmp".} =
      ## Register a new component.
      ## 
      ## ⚠ This is `Low-level API` ⚠
      ## 
      ## Don't use it because it used in `component` macro.
      ## 
      if components.hasKey(name):
        return components[name]
      components[name] = component
      component
  else:
    proc registerComponent*(name: string, component: BaseComponent): BaseComponent =
      ## Register a new component.
      ## 
      ## ⚠ This is `Low-level API` ⚠
      ## 
      ## Don't use it because it used in `component` macro.
      ## 
      if components.hasKey(name):
        return components[name]
      components[name] = component
      component


when defined(js):
  proc isSameTypes(a, b: Node): bool {.exportc: "ismtp".} =
    if a.nodeType == b.nodeType and a.nodeType == NodeType.ElementNode:
      return ($a.nodeName).toLower() == ($b.nodeName).toLower()
    return a.nodeType == b.nodeType
  proc attrIndex(e: Node): TableRef[cstring, cstring] {.exportc: "aidx".} =
    var attrs = newTable[cstring, cstring]()
    if e.attributes.len == 0:
      return attrs
    for i in e.attributes:
      attrs[i.nodeName] = i.nodeValue
    return attrs
  proc patchAttrs(dom, vdom: Node) {.exportc: "patrs".} =
    var
      domAttrs = dom.attrIndex
      vdomAttrs = vdom.attrIndex
    if domAttrs == vdomAttrs:
      return
    for key, val in vdomAttrs.pairs:
      if not domAttrs.hasKey(key):
        dom.setAttribute(key, val)
        if dom.nodeName == "INPUT" and key == "value":
          dom.InputElement.value = val
      elif domAttrs[key] != val:
        dom.setAttribute(key, val)
        if dom.nodeName == "INPUT" and key == "value":
          dom.InputElement.value = val
    for key, val in domAttrs.pairs:
      if not vdomAttrs.hasKey(key):
        dom.removeAttribute(key)
  proc diff*(vdom: TagRef, dom: Node) {.exportc: "dff".} =
    if not dom.hasChildNodes and vdom.hasChildNodes:
      for t in vdom.childNodes:
        dom.appendChild(t.cloneNode(true))
    else:
      {.emit: "if (`dom`.isEqualNode(`vdom`)){return}".}
      if dom.childNodes.len > vdom.childNodes.len:
        for i in 0..<(dom.childNodes.len - vdom.childNodes.len):
          dom.childNodes[^1].remove()
      for i in 0..<vdom.childNodes.len:
        if i >= dom.childNodes.len:
          dom.appendChild(vdom.childNodes[i].cloneNode(true))
        elif dom.childNodes[i].isSameTypes(vdom.childNodes[i]):
          if dom.childNodes[i].nodeType == NodeType.TextNode:
            if dom.childNodes[i].textContent != vdom.childNodes[i].textContent:
              dom.childNodes[i].textContent = vdom.childNodes[i].textContent
          else:
            dom.childNodes[i].patchAttrs(vdom.childNodes[i])
        else:
          dom.childNodes[i].replaceWith(vdom.childNodes[i].cloneNode(true))
        if vdom.childNodes[i].nodeType != NodeType.TextNode:
          diff(vdom.childNodes[i].TagRef, dom.childNodes[i])
  proc prerenderLazyProcs*(tag: TagRef) {.exportc: "prrndr".} =
    if tag.lazy:
      let t = tag.lazyFunc()
      t.prerenderLazyProcs()
      tag.parentElement.insertBefore(t, tag)
      tag.remove()
    else:
      for t in tag.childNodes:
        t.TagRef.prerenderLazyProcs()
  proc renderVdom*(app: App, tag: TagRef, force: bool = false) {.exportc: "rndrvd".} =
    ## Rerender DOM with VDOM
    var realDom = document.getElementById(app.appId).Node
    let activeElement = document.activeElement
    for i in rendererHandlers:
      if i.key == "beforeRendered":
        i.p()
    # let tempTag = tag.cloneNode(true).TagRef
    # tempTag.prerenderVdomProcs()
    # tempTag.diff(realDom)
    tag.prerenderLazyProcs()
    tag.diff(realDom)
    for i in rendererHandlers:
      if i.key == "rendered":
        i.p()
    when enableDefaultComponents:
      if force:
        for comp in createdComponentsList:
          comp.exited(comp, nil)
          components.del(comp.uniqCompId)
        for comp in currentComponentsList.mitems:
          comp = registerComponent(comp.uniqCompId, comp)
          comp.updated(comp, nil)
        createdComponentsList.setLen(0)
      else:
        for comp in currentComponentsList:
          comp.updated(comp, nil)
      currentComponentsList.setLen(0)
    if activeElement.hasAttribute("id"):
      let actElem = document.getElementById(activeElement.id)
      if not actElem.isNil:
        actElem.focus()
        if actElem.nodeName in ["INPUT".cstring, "TEXTAREA".cstring]:
          let
            oldActiveElem = activeElement.InputElement
            currentActiveElem = actElem.InputElement
          currentActiveElem.setSelectionRange(oldActiveElem.selectionStart, oldActiveElem.selectionEnd, oldActiveElem.selectionDirection)
else:
  proc renderVdom*(app: App, tag: TagRef, force: bool = false) =
    ## Rerender DOM with VDOM
    discard


when enableDefaultComponents:
  method render*(self: BaseComponent): TagRef {.base.} =
    ## Basic method that needs to overload in components
    nil


  method reRender*(self: BaseComponent) {.base.} =
    ## Basic method that needs to overload in components
    discard

{.pop.}


template start*(app: App) =
  ## Starts single page application
  ## 
  ## ⚠ This is `Low-level API` ⚠
  ## 
  ## use `appRoutes proc<#appRoutes.m,string>`_ instead of this
  ## because this procedure calls automatically.
  ## 
  when enableHistoryApi:
    once:
      document.addEventListener("popstate", onDOMContentLoaded)
    buildJs:
      function onPathChangeCallback():
        nim:
          let r: cstring = window.location.pathname
          if $r != $currentRoute:
            echo "route from ", currentRoute, " to ", r
            route(r)
      window.addEventListener("popstate", onPathChangeCallback)
    if window.location.hash.len == 0:
      route("/")
  else:
    once:
      document.addEventListener("hashchange", onDOMContentLoaded)
    buildJs:
      function onHashChangeCallback():
        nim:
          let r: cstring =
            if ($window.location.hash)[0] == '#':
              cstring(($window.location.hash)[1..^1])
            else:
              window.location.hash
          if $r != $currentRoute:
            echo "route from ", currentRoute, " to ", r
            route(r)
      window.addEventListener("hashchange", onHashChangeCallback)
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
  var cycleVars = newSeq[NimNode]()
  buildHtmlProcedure(root, html, cycleVars = cycleVars)


macro buildHtml*(html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## This macro doesn't generate Root tag
  ## 
  ## Args:
  ## - `html`: YAML-like structure.
  ## 
  var cycleVars = newSeq[NimNode]()
  result = buildHtmlProcedure(ident"tDiv", html, cycleVars = cycleVars)
  if result[^1].kind == nnkCall and $result[^1][0] == "@":
    result.add(newLit(true))


template lazyHtml*(body: untyped): proc(): TagRef =
  proc(): TagRef =
    result = buildHtml:
      body
    result = result.children[0].TagRef
    result.onlyChildren = true


template lazyHtmls*(body: untyped): seq[proc(): TagRef] =
  block:
    var res: seq[proc(): TagRef]
    template html(b: untyped) =
      res.add:
        proc(): TagRef =
          result = buildHtml:
            b
          result = result.children[0].TagRef
          result.onlyChildren = true
    body
    res


template buildHtmls*(body: untyped): seq[TagRef] =
  block:
    var res: seq[TagRef]
    template html(b: untyped) =
      res.add:
        buildHtml:
          b
      res[^1] = res[^1].children[0].TagRef
      res[^1].onlyChildren = true
    body
    res


when enableDefaultComponents:
  macro buildHtmlSlot*(html: untyped, inCycle, inComponent: static[bool]): untyped =
    ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
    ## This macro doesn't generate Root tag
    ## 
    ## Args:
    ## - `html`: YAML-like structure.
    ## 
    var cycleVars = newSeq[NimNode]()
    result = buildHtmlProcedure(
      ident"tDiv", html, cycleVars = cycleVars, inCycle = inCycle, inComponent = inComponent,
      cycleTmpVar = "cycleCounter", compTmpVar = ident"compCounter"
    ).add(newNimNode(nnkExprEqExpr).add(ident"onlyChildren", newLit(true)))


  macro buildComponentHtml*(componentName, html: untyped): untyped =
    ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
    ## This macro doesn't generate Root tag
    ## 
    ## Args:
    ## - `html`: YAML-like structure.
    ## 
    var
      h = html
      cycleVars = newSeq[NimNode]()
      node = h.replaceSelfComponent(componentName, convert = false)
    if node.kind != nnkEmpty:
      node.add(newCall("reRender", ident"self"))
    result = buildHtmlProcedure(ident"tDiv", h, true, componentName, compTmpVar = newDotExpr(ident"self", ident(UniqueComponentId)), cycleVars = cycleVars)
    if result[^1].kind == nnkCall and $result[^1][0] == "@":
      result.add(newLit(true))

when enableAppRouting:
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
        ident"activeElement",
        newDotExpr(ident"document", ident"activeElement")
      ),
      newLetStmt(
        ident"query",
        newCall("parseQuery", newCall("$", newDotExpr(newDotExpr(ident"window", ident"location"), ident"search")))
      ),
      newLetStmt(
        ident"queryArr",
        newCall("parseQueryArrays", newCall("$", newDotExpr(newDotExpr(ident"window", ident"location"), ident"search")))
      ),
      newLetStmt(
        ident"path",
        newCall(
          "strip",
          when enableHistoryApi:
            newCall("$", newDotExpr(newDotExpr(ident"window", ident"location"), ident"pathname"))
          else:
            newCall("$", newDotExpr(newDotExpr(ident"window", ident"location"), ident"hash")),
          newLit(true),
          newLit(false),
          newNimNode(nnkCurly).add(newLit('#'))
        )
      ),
      newNimNode(nnkVarSection).add(newIdentDefs(iHtml, ident"TagRef", newNilLit())),
      newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
        ident"enableDefaultComponents",
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
            newNimNode(nnkReturnStmt).add(newEmptyNode())
          )
        ))
      ))
    )

    # Find mounts
    body.findAndReplaceMount()

    for key, val in sugarRoutes.pairs():
      if ($val[0]).toLower() in ["build", "page", "any"]:
        body.add(newCall(newLit(key), val[1]))
    
    var
      cookiesInVar = newDotExpr(ident"document", ident"cookie")
      nextRouteDecorators: seq[tuple[name: string, args: seq[NimNode]]] = @[]
    
    for statement in body:
      if statement.kind in [nnkCommand, nnkCall, nnkPrefix]:
        if statement[^1].kind == nnkStmtList:
          # Check variable usage
          if statement[^1].isIdentUsed(ident"cookies"):
            statement[^1].insert(0, newVarStmt(ident"cookies", cookiesInVar))
        # Decorators
        if statement.kind == nnkPrefix and $statement[0] == "@" and statement[1].kind == nnkIdent:
          # @Decorator
          nextRouteDecorators.add(($statement[1], @[]))
        # @Decorator()
        elif statement.kind == nnkCall and statement[0].kind == nnkPrefix and $statement[0][0] == "@" and statement.len == 1:
          nextRouteDecorators.add(($statement[0][1], @[]))
        # @Decorator(arg1, arg2, ...)
        elif statement.kind == nnkCall and statement[0].kind == nnkPrefix and $statement[0][0] == "@" and statement.len > 1:
          nextRouteDecorators.add(($statement[0][1], statement[1..^1]))
          
        elif statement.len == 2 and statement[0].kind == nnkStrLit and statement[1].kind == nnkStmtList:
          for route in nextRouteDecorators:
            decorators[route.name](@[], $statement[0], statement[1], route.args)
          let exported = exportRouteArgs(
            iPath,
            statement[0],
            statement[1].copy()
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
          newCall("renderVdom", ident"application", iHtml, ident"force"),
          newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
            newCall("hasAttribute", ident"activeElement", newLit"id"),
            newStmtList(
              newLetStmt(
                ident"_activeElement_",
                newCall("getElementById", ident"document", newCall("id", ident"activeElement"))
              ),
              newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                newCall("not", newCall("isNil", ident"_activeElement_")),
                newStmtList(
                  newCall("focus", ident"_activeElement_"),
                  newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                    newCall(
                      "contains",
                      bracket(newCall("cstring", newLit"INPUT"), newCall("cstring", newLit"TEXTAREA")),
                      newDotExpr(ident"_activeElement_", ident"nodeName")
                    ),
                    newStmtList(
                      newLetStmt(ident"oldActiveElement", newCall("InputElement", ident"activeElement")),
                      newLetStmt(ident"currentActiveElement", newCall("InputElement", ident"_activeElement_")),
                      newCall(
                        "setSelectionRange",
                        ident"currentActiveElement",
                        newDotExpr(ident"oldActiveElement", ident"selectionStart"),
                        newDotExpr(ident"oldActiveElement", ident"selectionEnd"),
                        newDotExpr(ident"oldActiveElement", ident"selectionDirection"),
                      )
                    )
                  )),
                )
              )),
            )
          )),
        )
      ))
    )

    result = newStmtList(
      router,
      newAssignment(newDotExpr(ident"app", ident"router"), router.name),
      onDOMContentLoaded,
      if finalize.len > 0:
        newStmtList(
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident"emit",
            newLit(
              "window.addEventListener('beforeunload', (e) => {"
            )
          )),
          finalize,
          newNimNode(nnkPragma).add(newNimNode(nnkExprColonExpr).add(
            ident"emit",
            newLit(
              "});"
            )
          )
        ))
      else:
        newStmtList()
    )
    when enableDebugSpaMacro:
      echo result.toStrLit


  macro appRoutes*(name: string, body: untyped): untyped =
    ## Registers a new Single page application, creates routing for it and starts SPA.
    ## 
    ## `High-level API`
    ## 
    ## Use it to write your application.
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
      newCall("routes", ident"app", body),
      newCall("start", ident"app")
    )
