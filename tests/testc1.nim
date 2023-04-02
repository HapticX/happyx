import ../src/happyx


proc main =
  var server = newServer()

  server.routes:
    get "/":
      req.answer "Hello, world!"
    post "/":
      req.answer "Hello world with POST method!"
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
      echo reqMethod
  
  server.start()

main()
