## # State
## 
## Provides reactivity states
## 
import
  options


type
  State*[T] = object
    val*: Option[T]


func remember*[T](val: T): State[T] =
  ## Creates a new state
  State[T](val: some(val))


func `$`*(self: State): string =
  ## Returns string representation
  $self.val.get()


iterator items*[T](self: State[T]): auto =
  for item in self.val.get():
    yield item


converter bool*(self: State): bool = self.val.get()
converter string*(self: State): string = self.val.get()
converter int*(self: State): int = self.val.get()
converter float*(self: State): float = self.val.get()
converter char*(self: State): char = self.val.get()
converter int8*(self: State): int8 = self.val.get()
converter int16*(self: State): int16 = self.val.get()
converter int32*(self: State): int32 = self.val.get()
converter int64*(self: State): int64 = self.val.get()
converter float32*(self: State): float32 = self.val.get()
converter float64*(self: State): float64 = self.val.get()
