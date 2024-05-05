import ../src/happyx


serve("127.0.0.1", 5000):
  var userId = 0

  get "/":
    req.answer "Hello, world!"
  
  ws "/ws":
    echo wsData

  post "/":
    "Hello world with POST method!"

  get "/calc/{left:int}{operator:string}{right:int}":
    if operator == "+":
      fmt"Result of {left} + {right} is {left + right}"
    elif operator == "-":
      fmt"Result of {left} - {right} is {left - right}"
    else:
      "Oops! Unknown operator"
  
  get "/pattern{patternId:/[a-zA-Z0-9_]+/}":
    "pattern ID is {patternId}"
  
  get "/file/{file:path}":
    echo file

  get "/html":
    req.answerHtml:
      buildHtml(`div`):
        tScript(src="https://cdn.tailwindcss.com")  # Tailwind CSS :D
        tDiv(class="bg-gray-700 text-pink-400 px-8 py-24"):
          "Hello, world!"

  post "/user":
    inc userId
    return {"response": {"id": %userId}}
  
  get "/issue180":
    raise newException(ValueError, "Oops!")

  notfound:
    "Oops! Not found!"

  middleware:
    echo reqMethod
    echo urlPath
  
  let customRoute = "/tmpl"
  let customDir = "/templates"
  let customRoute1 = "/tmpl1"
  
  staticDir "testdir"
  staticDir "components"
  # Path -> directory
  staticDir "/public" -> "testdir"
  # path -> directory ~ extensions
  # On this path user can see only HTML, JS and CSS files
  staticDir "/pubdir" -> "testdir" ~ "html,js,css"
  # Path ~ extensions
  staticDir "/templates" ~ "html,js,css"

  staticDir customRoute -> customDir ~ "html,js,css,json"
  staticDir customRoute1 ~ "html,js,css"
  staticDir customRoute1 -> customDir
  staticDir customRoute1
