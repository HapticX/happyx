## # State 🍍
## 
## Provides reactivity states
## 
## ## Usage ⚡
## 
## .. code-block:: nim
##    var
##      lvl = remember 1
##      exp = remember 0
##      maxExp = remember 10
##      name = remember "Ethosa"
##    
##    appRoutes("app"):
##      "/":
##        tDiv:
##          "Hello, {name}, your level is {lvl} [{exp}/{maxExp}]"
##        tButton:
##          "Increase exp"
##          @click:
##            exp += 1
##            while exp >= maxExp:
##              exp -= maxExp
##              lvl += 1
##              maxExp += 5
##
import
  std/macros,
  std/tables,
  std/strtabs,
  ./renderer,
  ./translatable,
  ../core/constants,
  ../private/macro_utils


type
  StateChangeHandler*[T] = proc(newVal, oldVal: T)
  State*[T] = ref object
    val*: T
    watchers*: seq[StateChangeHandler[T]]


var enableRouting* = true  ## `Low-level API` to disable/enable routing


func remember*[T](val: T): State[T] =
  ## Creates a new state
  State[T](val: val)


func watchImpl[T](state: State[T], o, n: T) =
  for w in state.watchers:
    w(o, n)


when defined(js) or not enableLiveViews:
  proc `val=`*[T](self: State[T], value: T) =
    ## Changes state value
    if self.watchers.len > 0:
      self.watchImpl(self.val, value)
    self.val = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()
else:
  template `val=`*[T](self: State[T], value: T) =
    ## Changes state value
    if self.watchers.len > 0:
      self.watchImpl(self.val, value)
    self.val = value
    rerender(hostname, urlPath)


func `$`*[T](self: State[T]): string =
  ## Returns State's string representation
  when T is string:
    self.val
  else:
    $self.val


# func val*[T](self: State[T]): T =
#   ## Returns immutable state value
#   self.value

# when not defined(js):
#   func val*[T](self: var State[T]): var T =
#     ## Returns mutable state value
#     self.value


template operator(funcname, op: untyped): untyped =
  func `funcname`*[T](self, other: State[T]): T =
    `op`(self.value, other.value)
  func `funcname`*[T](other: T, self: State[T]): T =
    `op`(self.value, other)
  func `funcname`*[T](self: State[T], other: T): T =
    `op`(self.value, other)


when defined(js) or not enableLiveviews:
  template reRenderOperator(funcname, op: untyped): untyped =
    proc `funcname`*[T](self: State[T], other: State[T]) =
      if self.watchers.len > 0:
        let before = self.val
        `op`(self.val, other.val)
        self.watchImpl(before, self.val)
      else:
        `op`(self.val, other.val)
      if enableRouting and not application.isNil() and not application.router.isNil():
        application.router()
    proc `funcname`*[T](other: T, self: State[T]) =
      if self.watchers.len > 0:
        let before = self.val
        `op`(self.val, other)
        self.watchImpl(before, self.val)
      else:
        `op`(self.val, other)
      if enableRouting and not application.isNil() and not application.router.isNil():
        application.router()
    proc `funcname`*[T](self: State[T], other: T) =
      if self.watchers.len > 0:
        let before = self.val
        `op`(self.val, other)
        self.watchImpl(before, self.val)
      else:
        `op`(self.val, other)
      if enableRouting and not application.isNil() and not application.router.isNil():
        application.router()
else:
  template reRenderOperator(funcname, op: untyped): untyped =
    template `funcname`*[T](self: State[T], other: State[T]) =
      if self.watchers.len > 0:
        let before = self.val
        `op`(self.val, other.val)
        self.watchImpl(before, self.val)
      else:
        `op`(self.val, other.val)
      rerender(hostname, urlPath)
    template `funcname`*[T](other: T, self: State[T]) =
      if self.watchers.len > 0:
        let before = self.val
        `op`(self.val, other)
        self.watchImpl(before, self.val)
      else:
        `op`(self.val, other)
      rerender(hostname, urlPath)
    template `funcname`*[T](self: State[T], other: T) =
      if self.watchers.len > 0:
        let before = self.val
        `op`(self.val, other)
        self.watchImpl(before, self.val)
      else:
        `op`(self.val, other)
      rerender(hostname, urlPath)


template boolOperator(funcname, op: untyped): untyped =
  proc `funcname`*[T](self, other: State[T]): bool =
    `op`(self.val, other.val)
  proc `funcname`*[T](self: State[T], other: T): bool =
    `op`(self.val, other)


template unaryBoolOperator(funcname, op: untyped): untyped =
  proc `funcname`*[T](self: State[T]): bool =
    `op`(self.val)


boolOperator(`==`, `==`)
boolOperator(`!=`, `!=`)
boolOperator(`>=`, `>=`)
boolOperator(`<=`, `<=`)

unaryBoolOperator(`not`, `not`)

operator(`&`, `&`)
operator(`+`, `+`)
operator(`-`, `-`)
operator(`*`, `*`)
operator(`/`, `/`)
operator(`!`, `!`)
operator(`^`, `^`)
operator(`%`, `%`)
operator(`@`, `@`)
operator(`>`, `>`)
operator(`<`, `<`)

reRenderOperator(`*=`, `*=`)
reRenderOperator(`+=`, `+=`)
reRenderOperator(`-=`, `-=`)
reRenderOperator(`/=`, `/=`)
reRenderOperator(`^=`, `^=`)
reRenderOperator(`&=`, `&=`)
reRenderOperator(`%=`, `%=`)
reRenderOperator(`$=`, `$=`)
reRenderOperator(`@=`, `@=`)
reRenderOperator(`:=`, `:=`)
reRenderOperator(`|=`, `|=`)
reRenderOperator(`~=`, `~=`)


macro `->`*(self: State, field: untyped): untyped =
  ## Call any function that available for state value
  ## 
  ## ## Examples:
  ## 
  ## `Seqs`:
  ## 
  ## .. code-block::nim
  ##    var arr: State[seq[int]] = remember @[]
  ##    arr->add(1)
  ##    echo arr
  ## 
  ## `int`:
  ## 
  ## .. code-block::nim
  ##    var num = remember 0
  ##    num->inc()
  ##    echo num
  ## 
  if field.kind in nnkCallKinds:
    let call = newCall(field[0], newDotExpr(self, ident"val"))
    # Get func args
    if field.len > 1:
      for i in 1..<field.len:
        call.add(field[i])
    # When statement
    result = newNimNode(nnkWhenStmt).add(
      newNimNode(nnkElifBranch).add(
        # type(call()) is void
        newCall("is", newCall("type", call), ident"void"),
        newStmtList(
          newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
            newCall(">", newCall("len", newDotExpr(self, ident"watchers")), newLit(0)),
            newStmtList(
              newNimNode(nnkLetSection).add(newIdentDefs(
                ident"before", newEmptyNode(), newDotExpr(self, ident"val")
              )),
              call,
              newCall("watchImpl", self, ident"before", newDotExpr(self, ident"val")),
            )
          ), newNimNode(nnkElse).add(
            call
          )),
          # When defined JS
          newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
            newCall("or", newCall("defined", ident"js"), newCall("not", ident"enableLiveViews")),
            # If enableRouting and not application.isNil()
            newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
              newCall("and", ident"enableRouting", newCall("not", newCall("isNil", ident"application"))),
              # application.router()
              newCall(newDotExpr(ident"application", ident"router"))
            )),
          ), newNimNode(nnkElse).add(
            newCall("rerender", ident"hostname", ident"urlPath")
          )),
        )
      ), newNimNode(nnkElse).add(newStmtList(
        newVarStmt(ident"_result", 
          newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
            newCall(">", newCall("len", newDotExpr(self, ident"watchers")), newLit(0)),
            newStmtList(
              newNimNode(nnkLetSection).add(newIdentDefs(
                ident"before", newEmptyNode(), newDotExpr(self, ident"val")
              )),
              newLetStmt(ident"__ret", call),
              newCall("watchImpl", self, ident"before", newDotExpr(self, ident"val")),
            )
          ), newNimNode(nnkElse).add(
            call
          ))
        ),
        # When defined JS
        newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
          newCall("or", newCall("defined", ident"js"), newCall("not", ident"enableLiveViews")),
          # If enableRouting and not application.isNil()
          newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
            newCall("and", ident"enableRouting", newCall("not", newCall("isNil", ident"application"))),
            # application.router()
            newCall(newDotExpr(ident"application", ident"router"))
          )),
        ), newNimNode(nnkElse).add(
          newCall("rerender", ident"hostname", ident"urlPath")
        )),
        ident"_result"
      ))
    )
  elif field.kind == nnkIdent:
    result = newDotExpr(newDotExpr(self, ident"val"), field)
  else:
    result = newEmptyNode()


macro watch*(state, newVal, oldVal, body: untyped): untyped =
  ## Watch every value changing
  result = newCall("add",
    newDotExpr(state, ident"watchers"),
    newLambda(
      body,
      @[newEmptyNode(), newIdentDefs(newVal, ident"auto"), newIdentDefs(oldVal, ident"auto")]
    )
  )


func get*[T](self: State[T]): T =
  ## Returns state value
  ## Alias for `val procedure #val,State[T]`_
  self.val


func len*[T](self: State[T]): int =
  ## Returns state value length
  self.val.len


func low*[T](self: State[T]): int =
  ## Returns state value length
  self.val.low


func high*[T](self: State[T]): int =
  ## Returns state value length
  self.val.high


when defined(js):
  proc set*[T](self: State[T], value: T) =
    ## Changes state value and rerenders SPA
    if self.watchers.len > 0:
      self.watchImpl(self.val, value)
    self.val = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()
else:
  template set*[T](self: State[T], value: T) =
    ## Changes state value and rerenders SPA
    if self.watchers.len > 0:
      self.watchImpl(self.val, value)
    self.val = value
    rerender(hostname, urlPath)


func `[]`*[T, U](self: State[array[T, U]], idx: int): T =
  ## Returns State's item at `idx` index.
  self.val[idx]


func `[]`*[T](self: State[seq[T]], idx: int): T =
  ## Returns State's item at `idx` index.
  self.val[idx]


func `[]`*[T, U](self: State[array[T, U]], idx: State[int]): T =
  ## Returns State's item at `idx` index.
  self.val[idx.val]


func `[]`*[T](self: State[seq[T]], idx: State[int]): T =
  ## Returns State's item at `idx` index.
  self.val[idx.val]


func `[]`*[T, U](self: State[TableRef[T, U]], idx: T): U =
  ## Returns State's item at `idx` index.
  self.val[idx]


func `[]`*(self: State[StringTableRef], idx: string): string =
  ## Returns State's item at `idx` index.
  self.val[idx]

when defined(js) or not enableLiveViews:
  proc `[]=`*[T](self: State[seq[T]], idx: int, value: T) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()


  proc `[]=`*[T, U](self: State[array[T, U]], idx: int, value: T) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()


  proc `[]=`*[T, U](self: State[TableRef[T, U]], idx: T, value: U) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()


  proc `[]=`*(self: State[StringTableRef], idx: string, value: string) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()
else:
  proc `[]=`*[T](self: State[seq[T]], idx: int, value: T) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()


  proc `[]=`*[T, U](self: State[array[T, U]], idx: int, value: T) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()


  proc `[]=`*[T, U](self: State[TableRef[T, U]], idx: T, value: U) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()


  proc `[]=`*(self: State[StringTableRef], idx: string, value: string) =
    ## Changes State's item at `idx` index.
    if self.watchers.len > 0:
      let before = self.val
      self.val[idx] = value
      self.watchImpl(before, self.val)
    else:
      self.val[idx] = value
    if enableRouting and not application.isNil() and not application.router.isNil():
      application.router()


iterator items*[T](self: State[openarray[T]]): T =
  ## Iterate over state items
  for item in self.val:
    yield item


iterator pairs*[T, U](self: State[TableRef[T, U]]): (T, U) =
  ## Iterate over state items
  for k, v in self.val.pairs:
    yield (k, v)


converter toBool*(self: State[bool]): bool =
  ## Converts `State` into `boolean` if possible
  self.val
converter toString*(self: State[string]): string =
  ## Converts `State` into `string` if possible
  self.val
converter toCString*(self: State[cstring]): cstring =
  ## Converts `State` into `cstring` if possible
  self.val
converter toInt*(self: State[int]): int =
  ## Converts `State` into `int` if possible
  self.val
converter toFloat*(self: State[float]): float =
  ## Converts `State` into `float` if possible
  self.val
converter toChar*(self: State[char]): char =
  ## Converts `State` into `char` if possible
  self.val
converter toInt8*(self: State[int8]): int8 =
  ## Converts `State` into `int8` if possible
  self.val
converter toInt16*(self: State[int16]): int16 =
  ## Converts `State` into `int16` if possible
  self.val
converter toInt32*(self: State[int32]): int32 =
  ## Converts `State` into `int32` if possible
  self.val
converter toInt64*(self: State[int64]): int64 =
  ## Converts `State` into `int64` if possible
  self.val
converter toFloat32*(self: State[float32]): float32 =
  ## Converts `State` into `float32` if possible
  self.val
converter toFloat64*(self: State[float64]): float64 =
  ## Converts `State` into `float64` if possible
  self.val
converter toSeq*[T](self: State[seq[T]]): seq[T] =
  ## Converts `State` into `seq[T]` if possible
  self.val


{.cast(gcsafe).}:
  var languageSettings* =
    when defined(js):
      remember LanguageSettings(lang: "auto")
    else:
      LanguageSettings(lang: "auto")


when defined(js):
  proc set*(settings: State[LanguageSettings], lang: string) =
    settings.set(LanguageSettings(lang: lang))
else:
  proc set*(settings: var LanguageSettings, lang: string) =
    settings.lang = lang
