## # State
## 
## Provides reactivity states
##
import ./renderer


type
  State*[T] = ref object
    value: T


func remember*[T](val: T): State[T] =
  ## Creates a new state
  State[T](value: val)


proc `val=`*[T](self: State[T], value: T) =
  self.value = value
  application.router()


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
    repr self.val


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


func get*[T](self: State[T]): T =
  ## Returns state value
  self.val


proc set*[T](self: State[T], value: T) =
  ## Changes state value
  self.val = value


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
