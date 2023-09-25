## # Use Macro ✨
## 
## > `use` macro provides working with components
## 
## This statement is useful to keep components into variable.
## 
## ## Components 🍍
## 
## .. code-block::nim
##    var comp1 = use:
##      component MyComponent(...):
##        ...
##    
##    component.method()
##    component.field += 1
##    
##    buildHtml:
##      component comp1
## 
import
  # stdlib
  macros,
  strformat,
  # HappyX
  ../core/[exceptions],
  ../private/macro_utils


macro use*(expr: untyped, inComp: static[bool] = false, compTmpVar: string = ""): untyped =
  ## Uses some expressions as variable
  ## 
  ## At this moment expressions are only component
  ## 
  var statement = expr

  if expr.kind == nnkStmtList:
    if expr.len > 1:
      throwDefect(
        HpxUseDefect,
        fmt"`use` statement allows only one statement in statement list, but got {expr.len} statements.",
        lineInfoObj(expr)
      )
    statement = expr[0]
  var cycleVars = newSeq[NimNode]()
  
  if statement.kind in nnkCallKinds:
    # Default constructor
    if statement[1].kind in {nnkIdent, nnkCall}:
      result = useComponent(statement, false, inComp, "", compTmpVar, cycleVars, false)
      return result
    # Component constructor
    elif statement[1].kind == nnkInfix:
      result = useComponent(statement, false, inComp, "", compTmpVar, cycleVars, false, constructor = true)
      return result
  else:
    throwDefect(
      HpxUseDefect,
      fmt"`use` statement allow only nnkCall nodes, but got {statement.kind} node",
      lineInfoObj(statement)
    )
