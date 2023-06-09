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
##          "Hello, {name}, your level is {lvl} [{exp}/{maxExp}"
##        tButton:
##          "Increase exp"
##          @click:
##            inc exp
##            while exp >= maxExp:
##              exp -= maxExp
##              inc lvl
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
  self.value = value
  application.router()


func val*[T](self: var State[T]): var T = self.value
func val*[T](self: State[T]): T = self.value


template operator(funcname, op: untyped): untyped =
  func `funcname`*[T](self, other: State[T]): T =
    `op`(self.value, other.value)
  func `funcname`*[T](self: State[T], other: T): T =
    `op`(self.value, other)


template reRenderOperator(funcname, op: untyped): untyped =
  proc `funcname`*[T](self: State[T], other: State[T]) =
    `op`(self.val, other.val)
    application.router()
  proc `funcname`*[T](self: State[T], other: T) =
    `op`(self.value, other)
    application.router()


template boolOperator(funcname, op: untyped): untyped =
  proc `funcname`*[T](self, other: State[T]): bool =
    `op`(self.val, other.val)
  proc `funcname`*[T](self: State[T], other: T): bool =
    `op`(self.val, other)


template unaryBoolOperator(funcname, op: untyped): untyped =
  proc `funcname`*[T](self: State[T]): bool =
    `op`(self.val)


func `$`*[T](self: State[T]): string =
  ## Returns string representation
  when T is string:
    self.val
  else:
    $self.val


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
  ## Changes state value
  self.val = value
  application.router()


func `[]`*[T](self: State[T], idx: int): auto =
  self.val[idx]


iterator items*[T](self: State[T]): auto =
  for item in self.val:
    yield item


converter toBool*(self: State): bool = self.val
converter toString*(self: State): string = self.val
converter toCString*(self: State): cstring = self.val
converter toInt*(self: State): int = self.val
converter toFloat*(self: State): float = self.val
converter toChar*(self: State): char = self.val
converter toInt8*(self: State): int8 = self.val
converter toInt16*(self: State): int16 = self.val
converter toInt32*(self: State): int32 = self.val
converter toInt64*(self: State): int64 = self.val
converter toFloat32*(self: State): float32 = self.val
converter toFloat64*(self: State): float64 = self.val
converter toSeq*[T](self: State[seq[T]]): seq[T] = self.val

