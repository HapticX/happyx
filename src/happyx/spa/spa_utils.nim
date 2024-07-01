## # SPA Utils
## This module provides macros and functions to simplify the integration of Nim code with JavaScript (JS).
## It includes macros for working with timeouts, intervals, promises, event listeners, and variables, as well as functions for awaiting promises and clearing timeouts and intervals.
## 
import
  std/macros,
  std/macrocache,
  std/strutils,
  std/asyncjs,
  std/jsffi

export
  jsffi,
  asyncjs


const utilCounter* = CacheCounter"HappyXUtilsCounter"

proc await*(obj: JsObject): JsObject {.discardable, importjs: "(await #)".}
macro await*(p: untyped): untyped =
  ## Waits for a promise to resolve before continuing execution, similar to `await` in JS.
  let id = "__res" & $utilCounter.value
  let callId = "__call" & $utilCounter.value
  inc utilCounter
  result = newStmtList(
    newNimNode(nnkVarSection).add(newIdentDefs(ident(id), ident"JsObject", newEmptyNode())),
    newVarStmt(ident(callId), p),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & id & "` = await `" & callId & "`")
      )
    ),
    ident(id)
  )
proc clearTimeout*(x: JsObject): JsObject {.discardable, importjs: "clearTimeout(#)".}
  ## Clears a timeout previously set with `withTimeout`.
proc clearInterval*(x: JsObject): JsObject {.discardable, importjs: "clearInterval(#)".}
  ## Clears an interval previously set with `withInterval`.


macro eventListener*(obj: untyped, event: string, body: untyped): untyped =
  ## Creates an event listener in Nim that corresponds to `addEventListener` in JS.
  ## 
  ## ## Example
  ## ```nim
  ## var e = document.querySelector("#some-element-id")
  ## e.eventListener("click"):
  ##   echo "clicked!"
  ## ```
  newStmtList(
    if obj.kind == nnkIdent:
      newNimNode(nnkPragma).add(
        newNimNode(nnkExprColonExpr).add(
          ident"emit",
          newLit("`" & $obj & "`.addEventListener('" & $event & "', async (event) => {")
        )
      )
    else:
      let id = "__el_ev" & $utilCounter.value
      inc utilCounter
      newStmtList(
        newVarStmt(ident(id), obj),
        newNimNode(nnkPragma).add(
          newNimNode(nnkExprColonExpr).add(
            ident"emit",
            newLit("`" & id & "`.addEventListener('" & $event & "', async (event) => {")
          )
        )
      ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("});")
      )
    ),
  )


macro withVariables*(variables: varargs[untyped]): untyped =
  ## Passes variables to other macros (`withTimeout`, `withInterval`, `withPromise`).
  var names: seq[string] = @[]
  for i in variables[0..^2]:
    names.add("`" & $i & "`")
  newNimNode(nnkBlockStmt).add(newEmptyNode(), newStmtList(
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("const __withVariables = (" & names.join(",") & ") => {")
      )
    ),
    variables[^1],
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("};\n__withVariables(" & names.join(",") & ");")
      )
    ),
  ))


macro withTimeout*(time: int, id, body: untyped): untyped =
  ## Executes code after a specified timeout, similar to `setTimeout` in JS.
  ## 
  ## ## Example
  ## ```nim
  ## withTimeout 1000, t:
  ##   clearInterval(t)
  ##   {.emit: "res(true)".}
  ## ```
  newNimNode(nnkBlockStmt).add(newEmptyNode(), newStmtList(
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident"__timeoutTime", ident"cint", time)
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("let " & $id & " = setTimeout(() => {")
      )
    ),
    newNimNode(nnkVarSection).add(
      newIdentDefs(id, ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & $id & "` = " & $id & ";")
      )
    ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("}, `__timeoutTime`);")
      )
    ),
  ))


macro js*(obj: untyped): untyped =
  ## Converts Nim code into JavaScript equivalent.
  ## 
  ## This macro allows embedding Nim code directly into JavaScript context.
  newNimNode(nnkBlockStmt).add(newEmptyNode(), newStmtList(
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident"__o", ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`__o` = " & $obj.toStrLit & ";")
      )
    ),
    ident"__o"
  ))


macro withInterval*(time: static[int], ident, body: untyped): untyped =
  ## Executes code repeatedly with a specified interval, similar to `setInterval` in JS.
  ## 
  ## ## Example
  ## ```nim
  ## withInterval 1000, i:
  ##   clearInterval(i)
  ##   {.emit: "res(true)".}
  ## ```
  newNimNode(nnkBlockStmt).add(newEmptyNode(), newStmtList(
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("let " & $ident & " = setInterval(() => {")
      )
    ),
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident, ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & $ident & "` = " & $ident & ";")
      )
    ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("}," & $time & ");")
      )
    ),
  ))


macro withPromise*(ident, body: untyped): untyped =
  ## Executes code asynchronously and returns a promise, similar to creating a promise in JS.
  ## 
  ## ## Example
  ## ```nim
  ## let promise = withPromise res:
  ##   withTimeout 1000, t:
  ##     clearTimeout(t)
  ##     {.emit: "res(true)".}
  ## ```
  result = newStmtList(
    newNimNode(nnkVarSection).add(
      newIdentDefs(
        ident"__promise",
        ident"JsObject",
        newEmptyNode()
      )
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`__promise` = new Promise(" & $ident & " => {")
      )
    ),
    newNimNode(nnkVarSection).add(
      newIdentDefs(ident, ident"JsObject", newEmptyNode())
    ),
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit",
        newLit("`" & $ident & "` = " & $ident & ";")
      )
    ),
    body,
    newNimNode(nnkPragma).add(
      newNimNode(nnkExprColonExpr).add(
        ident"emit", newLit("});")
      )
    ),
    ident"__promise"
  )


proc sleepAsyncJs*(time: int) {.async, discardable.} =
  await:
    withPromise response:
      withTimeout time, i:
        {.emit: "`response`(true);".}
        clearTimeout(i)
