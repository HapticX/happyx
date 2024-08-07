import ../src/happyx

type
  Kind = enum
    circle
    square

model Obj:
  k: Kind
  st: string


proc voidTest =
  echo 1


serve("127.0.0.1", 5000):
  post "/[data:Obj:json]":
    echo data
    return ""
  
  get "/":
    buildHtml:
      tDiv(class="hello\" style=\"color:green"):
        "hello <b>world</b>"

  get "/issue287":
    statusCode = 200
    return 0
  post "/issue287":
    statusCode = 200
    return 0
  
  get "/hello":
    voidTest()

  onException:
    echo "Exception"
    echo e.name
    echo e.msg
    statusCode = 422
    echo statusCode
    return "Exception"
