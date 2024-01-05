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
