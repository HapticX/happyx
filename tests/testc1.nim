import ../src/happyx


proc main =
  var server = newServer()

  server.routes:
    "/":
      req.answer "Hello, world!"
    "/calc/{left:int}{operator:string}{right:int}":
      if operator == "+":
        req.answer fmt"Result of {left} + {right} is {left + right}"
      elif operator == "-":
        req.answer fmt"Result of {left} - {right} is {left - right}"
      else:
        req.answer fmt"Oops! Unknown operator"
    notfound:
      req.answer "Oops! Not found!"
    middleware:
      echo req
  
  server.start()

main()
