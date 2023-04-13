## # State
## 
## Provides reactivity states
##

type
  State*[T] = object
    val*: T


func remember*[T](val: T): State[T] =
  ## Creates a new state
  State[T](val: val)


template operator(op: untyped): untyped =
  func `op`*[T](self, other: State[T]): T =
    `op`(self.val, other.val)


func `$`*(self: State): string =
  ## Returns string representation
  repr self.val


func `==`*[T](self, other: State[T]): bool =
  ## Returns self == other
  self.val == other.val


operator(`&`)
operator(`+`)
operator(`-`)
operator(`*`)
operator(`/`)


func get*[T](self: State[T]): T =
  ## Returns state value
  self.val


func set*[T](self: State[T], value: T) =
  ## Changes state value
  self.val = value


func `[]`*[T](self: State[T], idx: int): auto =
  self.val[idx]


iterator items*[T](self: State[T]): auto =
  for item in self.val:
    yield item


converter bool*(self: State): bool = self.val
converter string*(self: State): string = self.val
converter int*(self: State): int = self.val
converter float*(self: State): float = self.val
converter char*(self: State): char = self.val
converter int8*(self: State): int8 = self.val
converter int16*(self: State): int16 = self.val
converter int32*(self: State): int32 = self.val
converter int64*(self: State): int64 = self.val
converter float32*(self: State): float32 = self.val
converter float64*(self: State): float64 = self.val
