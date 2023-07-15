## # Use Macro ✨
## 
## > `use` macro provides working with components
## 
import
  macros,
  ../core/[exceptions, constants],
  ../spa/components,
  ../private/macro_utils


macro use*(expr: untyped): untyped =
  ## Uses some expressions as variable
  ## 
  ## At this moment expressions are only component
  ## 
  var statement = expr

  if expr.kind == nnkStmtList:
    if expr.len > 1:
      throwDefect(
        HpxUseDefect,
        "use allow only one object - component or path param",
        lineInfoObj(expr)
      )
    statement = expr[0]
  
  if statement.kind in nnkCallKinds:
    return useComponent(statement, false, false, "", @[], false)
  else:
    throwDefect(
      HpxUseDefect,
      "use allow only call nodes",
      lineInfoObj(statement)
    )
