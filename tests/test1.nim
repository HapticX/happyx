import
  unittest,
  strformat,
  ../src/happyx


proc main =
  var server = newServer("127.0.0.1", 5000)

  server.routes:
    route("/"):
      req.answer "Hello, world!"
    "/bye":
      req.answer "Bye!"
    "/bye{id:int}":
      req.answer fmt"Bye!, {id}"
    notfound:
      req.answer "Oops! Not found!"
  
  server.start()

main()
