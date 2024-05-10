import ../src/happyx

type
  Kind = enum
    circle
    square

model Obj:
  k: Kind
  st: string

serve("127.0.0.1", 5000):
  post "/[data:Obj:json]":
    echo data
    return ""

  onException:
    echo "Exception"
    echo e.name
    echo e.msg
    statusCode = 422
    echo statusCode
    return "Exception"
