import ../src/happyx


type Kind = enum
  str
  num


model Task:
  id: int


serve "127.0.0.1", 5000:
  post "/[task:Task]":
    echo task.id
    return task.id
  
  get "/x/$x":
    if x == "1":
      return x
    echo 1
    if x == "2":
      return x
    echo 2
    return x
    echo x

  get "/thisShouldWorkWhithoutRegex":
    discard

  get "/{k:enum(Kind)}/{x}":
    "1" & x
  get "/bool":
    "2"
  notfound:
    "3"
  
  staticDir "/testdir"

  staticDir "/testdir" -> "testdir" ~ "html,js,css"

  middleware:
    outHeaders["x"] = "y"
  
  onException:
    # here built-in variables:
    # `url`, `body` is string
    # `e` is `ref Exception`
    echo "URL: ", url
    echo "BODY: ", body
    echo "EXCEPTION: [", e.name, "] - ", e.msg
