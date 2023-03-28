import
  unittest,
  strformat,
  ../src/happyx


proc main =
  var server = newServer()

  server.routes:
    route("/"):
      req.answer "Hello, world!"
    "/bye":
      req.answer "Bye!"
    "/bye{id:int}":
      req.answer fmt"Bye!, {id}"
    "/user{id:int}/file/{file:path}":
      echo id
      echo file
      req.answer fmt"Bye!, {id} [{file}]"
    "/calc/{left:int}{operator:string}{right:int}":
      if operator == "+":
        req.answer fmt"Result of {left} + {right} is {left + right}"
      elif operator == "-":
        req.answer fmt"Result of {left} - {right} is {left - right}"
      else:
        req.answer fmt"Oops! Unknown operator"
    notfound:
      req.answer "Oops! Not found!"
  
  server.start()

main()
