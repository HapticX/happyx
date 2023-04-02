import ../src/happyx


proc main =
  var
    server = newServer()
    userId = 0

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

    get "/html":
      let html = buildHtml(`div`):
        `div`(class="div"):
          "Hello, world!"
        style:
          """
          .div {
            background-color: #212121;
            color: #fecefe;
          }
          """
      req.answerHtml $html

    post "/user":
      inc userId
      req.answerJson %*{
        "response": {
          "id": %userId
        }
      }

    notfound:
      req.answer "Oops! Not found!"

    middleware:
      echo reqMethod
  
  server.start()

main()
