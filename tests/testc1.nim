import ../src/happyx


serve("127.0.0.1", 5000):
  var userId = 0

  get "/":
    req.answer "Hello, world!"
  
  ws "/ws":
    echo wsData
    echo wsClient.key
    echo wsClient.version
    echo wsClient.protocol

  post "/":
    "Hello world with POST method!"

  "/calc/{left:int}{operator:string}{right:int}":
    if operator == "+":
      fmt"Result of {left} + {right} is {left + right}"
    elif operator == "-":
      fmt"Result of {left} - {right} is {left - right}"
    else:
      fmt"Oops! Unknown operator"
  
  get "/pattern{patternId:/[a-zA-Z0-9_]+/}":
    "pattern ID is {patternId}"
  
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
    return {"response": {"id": %userId}}

  notfound:
    "Oops! Not found!"

  middleware:
    echo reqMethod
    echo urlPath
  
  staticDir "testdir"
  staticDir "components"
  staticDir "/public" -> "testdir"
