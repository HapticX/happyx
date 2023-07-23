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
  macros,
  ./renderer


type
  State*[T] = ref object
    value: T


func remember*[T](val: T): State[T] =
  ## Creates a new state
  State[T](value: val)


proc `val=`*[T](self: State[T], value: T) =
  ## Changes state value
  self.value = value
  if not application.isNil() and not application.router.isNil():
    application.router()


func `$`*[T](self: State[T]): string =
  ## Returns State's string representation
  when T is string:
    self.value
  else:
    $self.value


func val*[T](self: State[T]): T =
  ## Returns immutable state value
  self.value


template operator(funcname, op: untyped): untyped =
  func `funcname`*[T](self, other: State[T]): T =
    `op`(self.value, other.value)
  func `funcname`*[T](self: State[T], other: T): T =
    `op`(self.value, other)


template reRenderOperator(funcname, op: untyped): untyped =
  proc `funcname`*[T](self: State[T], other: State[T]) =
    `op`(self.val, other.val)
    if not application.isNil() and not application.router.isNil():
      application.router()
  proc `funcname`*[T](self: State[T], other: T) =
    `op`(self.value, other)
    if not application.isNil() and not application.router.isNil():
      application.router()


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
    let
      funcName = $field[0].toStrLit
      call = newCall(field[0], newDotExpr(self, ident("val")))
    # Get func args
    if field.len > 1:
      for i in 1..<field.len:
        call.add(field[i])
    # When statement
    result = newNimNode(nnkWhenStmt).add(
      newNimNode(nnkElifBranch).add(
        # type(call()) is void
        newCall("is", newCall("type", call), ident("void")),
        call
      ), newNimNode(nnkElse).add(newStmtList(
        newVarStmt(ident("_result"), call),
        # When defined JS
        newNimNode(nnkWhenStmt).add(newNimNode(nnkElifBranch).add(
          newCall("defined", ident("js")),
          # If not application.isNil()
          newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
            newCall("not", newCall("isNil", ident("application"))),
            # application.router()
            newCall(newDotExpr(ident("application"), ident("router")))
          )),
        )),
        ident("_result")
      ))
    )
  elif field.kind == nnkIdent:
    result = newDotExpr(newDotExpr(self, ident("val")), field)
  else:
    result = newEmptyNode()


func get*[T](self: State[T]): T =
  ## Returns state value
  self.val


func len*[T](self: State[T]): int =
  ## Returns state value length
  self.value.len


proc set*[T](self: State[T], value: T) =
  ## Changes state value and rerenders SPA
  self.val = value
  if not application.isNil() and not application.router.isNil():
    application.router()


func `[]`*[T](self: State[T], idx: int): auto =
  ## Returns State's item at `idx` index.
  self.val[idx]


iterator items*[T](self: State[T]): auto =
  ## Iterate over state items
  for item in self.val:
    yield item


converter toBool*(self: State[bool]): bool =
  ## Converts `State` into `boolean` if possible
  self.value
converter toString*(self: State[string]): string =
  ## Converts `State` into `string` if possible
  self.value
converter toCString*(self: State[cstring]): cstring =
  ## Converts `State` into `cstring` if possible
  self.value
converter toInt*(self: State[int]): int =
  ## Converts `State` into `int` if possible
  self.value
converter toFloat*(self: State[float]): float =
  ## Converts `State` into `float` if possible
  self.value
converter toChar*(self: State[char]): char =
  ## Converts `State` into `char` if possible
  self.value
converter toInt8*(self: State[int8]): int8 =
  ## Converts `State` into `int8` if possible
  self.value
converter toInt16*(self: State[int16]): int16 =
  ## Converts `State` into `int16` if possible
  self.value
converter toInt32*(self: State[int32]): int32 =
  ## Converts `State` into `int32` if possible
  self.value
converter toInt64*(self: State[int64]): int64 =
  ## Converts `State` into `int64` if possible
  self.value
converter toFloat32*(self: State[float32]): float32 =
  ## Converts `State` into `float32` if possible
  self.value
converter toFloat64*(self: State[float64]): float64 =
  ## Converts `State` into `float64` if possible
  self.value
converter toSeq*[T](self: State[seq[T]]): seq[T] =
  ## Converts `State` into `seq[T]` if possible
  self.value

