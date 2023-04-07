import ../src/happyx


initServer:
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
    
    get "/pattern{patternId:/[a-zA-Z0-9_]+/}":
      req.answer fmt"pattern ID is {patternId}"
    
    get "/file/{file:path}":
      echo file

    get "/html":
      req.answerHtml:
        buildHtml(`div`):
          script(src="https://cdn.tailwindcss.com")  # Tailwind CSS :D
          `div`(class="bg-gray-700 text-pink-400 px-8 py-24"):
            "Hello, world!"

    post "/user":
      inc userId
      req.answerJson {"response": {"id": %userId}}

    notfound:
      req.answer "Oops! Not found!"

    middleware:
      echo reqMethod
      echo urlPath
    
    staticDir "testdir"
  
  server.start()
