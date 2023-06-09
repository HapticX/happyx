## # Components ✨
## 
## Now components fully support in `SPA` projects.
## 
## `SSR` project support components without event handlers and JS features.
## 
import
  # Stdlib
  strformat,
  macros,
  # HappyX
  ./renderer,
  ../sugar/[js, style],
  ../core/[exceptions],
  ../private/[macro_utils]


proc replaceSelfStateVal(statement: NimNode) =
  for idx, i in statement.pairs:
    if i.kind == nnkDotExpr:
      if $i.toStrLit == "self":
        statement[idx] = newCall("get", newDotExpr(i[0], i[1]))
      continue
    if i.kind in RoutineNodes:
      continue
    i.replaceSelfStateVal()


macro component*(name, body: untyped): untyped =
  ## Register a new component.
  ## 
  ## ## Basic Usage 🔨
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
  ## ## Pure Css 🎈
  ## 
  ## You can use `buildStyle` macro syntax inside `` `style` ``
  ## 
  ## .. code-block:: nim
  ##    
  ##    component MyComponent:
  ##      ...
  ##      `style` as css:
  ##        tag tDiv:
  ##          background-color: rgb(100, 200, 255)
  ##        tDiv@hover:
  ##          padding: 0 8.px 2.rem 1.em
  ## 
  ## ## Pure JavaScript ✌
  ## 
  ## You also can use `buildJs` macro syntax inside `` `script` ``
  ## 
  ## .. code-block:: nim
  ##    ...
  ##    `script` as js:
  ##      function myFunc(a, b, c):
  ##        echo a, b, c
  ##      
  ##      class MyClass:
  ##        constructor():
  ##          echo "Hi"
  ##      
  ##      var myCls = new MyClass()
  ##      myFunc(1, 2, 3)
  ## 
  ## ## Slots 👨‍🔬
  ## 
  ## Slots is extends your component
  ## 
  ## Declaration:
  ## 
  ## .. code-block::nim
  ##    component Component:
  ##      `template`:
  ##        tDiv:
  ##          slot
  ## 
  ## Usage:
  ## 
  ## .. code-block::nim
  ##    buildHtml:
  ##      component Component(...):
  ##        tDiv(...):
  ##          "This div tag with this text will shown in component slot"
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
        when defined(js):
          newAssignment(
            newDotExpr(
              newCall("querySelector", ident("document"), ident("tmpData")),
              ident("outerHTML")
            ),
            newCall("cstring", newCall("$", ident("compTmpData")))
          )
        else:
          newCall(
            "add",
            ident("compTmpData"),
            newCall(
              "initTag",
              newStrLitNode("script"),
              newCall("@", newNimNode(nnkBracket).add(newCall("textTag",
                newCall("&", newCall(
                    "&", newCall(
                      "fmt", newStrLitNode("document.querySelector('{tmpData}').outerHTML = `")
                    ),
                    newCall("$", ident("compTmpData"))
                  ), newStrLitNode("`;")
                )
              )))
            )
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
    if s.kind in [nnkCall, nnkCommand, nnkInfix]:
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
    
      elif s[0].kind == nnkAccQuoted or s.kind == nnkInfix and s[1].kind == nnkAccQuoted:
        var
          asType = ""
          acc: NimNode = nil
        if s[0].kind == nnkAccQuoted:
          acc = s[0]
        else:
          acc = s[1]
          asType = $s[2]
        case $acc
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
                s[^1].add(newCall(
                  "style", newStmtList(newStrLitNode("{self.style()}"))
                ))
              )
            ),
            afterStmtList,
            newAssignment(ident("currentComponent"), newStrLitNode(""))
          )
        of "style":
          # Component styles
          if asType != "":
            # Pure CSS on as css
            if asType.toLower() != "css":
              throwDefect(
                HpxComponentDefect,
                fmt"style as {asType} is invalid. Should be 'style as css'! ",
                lineInfoObj(s)
              )
            let css = getAst(buildStyle(s[^1]))[1]
            let str = ($css).replace(
              re"^([\S ]+?) *\{(?im)", "$1[data-<self.uniqCompId>]{"
            ).replace(re"(^ *|\{ *|\n *)\}(?im)", "$1}")
            styleStmtList = newStmtList(
              newAssignment(
                ident("result"),
                newCall("fmt", newStrLitNode(str), newLit('<'), newLit('>'))
              )
            )
          elif s[^1][0].kind in [nnkStrLit, nnkTripleStrLit]:
            # String CSS
            let str = ($s[1][0]).replace(
              re"^([\S ]+?) *\{(?im)", "$1[data-{self.uniqCompId}]{{"
            ).replace(re"(^ *|\{ *|\n *)\}(?im)", "$1}}")
            styleStmtList = newStmtList(
              newAssignment(
                ident("result"),
                newCall("fmt", newStrLitNode(str))
              )
            )
          elif s[^1][0].kind == nnkCall and s[^1][0][0].kind == nnkIdent and $s[^1][0][0] == "buildStyle":
            # Pure CSS
            let css = getAst(buildStyle(s[^1][0][1]))[1]
            let str = ($css).replace(
              re"^([\S ]+?) *\{(?im)", "$1[data-<self.uniqCompId>]{"
            ).replace(re"(^ *|\{ *|\n *)\}(?im)", "$1}")
            styleStmtList = newStmtList(
              newAssignment(
                ident("result"),
                newCall("fmt", newStrLitNode(str), newLit('<'), newLit('>'))
              )
            )
          else:
            throwDefect(
              HpxComponentDefect,
              "unknown style syntax ",
              lineInfoObj(s)
            )
        of "script":
          # Component main script
          if asType != "":
            # Pure JavaScript
            when not defined(js):
              throwDefect(
                HpxComponentDefect,
                "as js available only on JS backend ",
                lineInfoObj(s)
              )
            if asType.toLower() != "js":
              throwDefect(
                HpxComponentDefect,
                fmt"style as {asType} is invalid. Should be 'style as css'! ",
                lineInfoObj(s)
              )
            scriptStmtList = newStmtList(
              getAst(buildJs(s[^1]))
            )
          else:
            s[^1].replaceSelfStateVal()
            scriptStmtList = s[^1]
        else:
          let structure = $s[0]
          throwDefect(
            HpxComponentDefect,
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
            HpxComponentDefect,
            fmt"Wrong component event ({key})",
            lineInfoObj(s)
          )
    else:
      throwDefect(
        HpxComponentDefect,
        "Unknown component declaration syntax ",
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
      scriptStmtList,
      pragmas =
        when defined(js):
          newEmptyNode()
        else:
          newNimNode(nnkPragma).add(ident("gcsafe"))
    ),
    newProc(
      ident("style"),
      [
        ident("string"),
        newIdentDefs(ident("self"), ident(name))
      ],
      styleStmtList,
      pragmas =
        when defined(js):
          newEmptyNode()
        else:
          newNimNode(nnkPragma).add(ident("gcsafe"))
    ),
    newProc(
      postfix(ident("render"), "*"),
      [
        ident("TagRef"),
        newIdentDefs(ident("self"), ident(name))
      ],
      templateStmtList,
      nnkMethodDef,
      pragmas =
        when defined(js):
          newEmptyNode()
        else:
          newNimNode(nnkPragma).add(ident("gcsafe"))
    ),
  )