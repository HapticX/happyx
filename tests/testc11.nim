import ../src/happyx


type MyType = object
  field: int

proc `$`*(self: MyType): string =
  "MyType(a = " & $self.field & ")"

var
  data = remember @[1, 2, 3]
  setData = remember {2, 4, 8, 16, 128}
  myType = remember MyType(field: 100)
  jsonVar = remember %*{"a": 1, "b": 2, "c": 3}

echo myType->field
echo typeof(jsonVar.val)

discard data->pop()
data->add(1)
data->insert(100, 0)

setData->incl(32)
setData->excl(4)

echo data
echo setData
echo jsonVar

# for i in data->items():
#   echo i
