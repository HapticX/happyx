import ../src/happyx


templateFolder("templates")

proc render(title: string, left: float, right: float): string =
  renderTemplate("index.html")


pathParams:
  arg1? int[m] = 100
  arg2? int = 100
  arg3 int = 100
  arg4
  arg5 int
  arg6 int[m]
  arg7 = "100"
  arg8[m] = 100
  arg9 int:
    type int
    optional
    mutable
    default = 100


serve "127.0.0.1", 5000:
  let some = 100
  var counter = 0

  get "/{title:string}/{left:float}/{right:float}":
    ## Calculate left and right. Shows title.
    ## 
    ## @openapi {
    ##  operationId = calculate
    ##  summary = calculate left and right.
    ##  
    ##  @params {
    ##    title: string - just title
    ##    left: integer - left number
    ##    right: integer - right number
    ##  }
    ##  
    ##  @responses {
    ##    asdad
    ##  }
    ## }
    req.answerHtml render(title, left, right)
  
  get "/":
    inc counter
    "counter = {counter}"
  
  get "/mutablePathParams/$arg[m]/<arg1>":
    arg &= "00000000000"
    arg1 += 100
    "\"{arg}\" and \"{arg1}\""
  
  get "/setCheckTo{arg:bool}":
    if arg:
      "true!"
    else:
      "false!"
  
  get "/pathParams/$arg/$arg1:bool/$arg2=2":
    let name = query?name
    req.answerHtml:
      buildHtml:
        tDiv:
          "arg is {arg}"
        tDiv:
          "arg1 is {arg1}"
        tDiv:
          "arg2 is {arg2}"
        tDiv:
          "My name is {name}"


  get "/optional/{arg?:bool}{arg1?:int}{arg2?:bool}{arg3?:float}{arg4?:string}":
    buildHtml:
      tDiv:
        "arg is {arg}"
      tDiv:
        "arg1 is {arg1}"
      tDiv:
        "arg2 is {arg2}"
      tDiv:
        "arg3 is {arg3}"
      tDiv:
        "arg4 is \"{arg4}\""

  get "/default/{arg?:bool=true}{arg1:bool=true}{arg2?:int=123}{arg3:int=123123}{arg4:word=Hi}":
    buildHtml:
      tDiv:
        "arg is {arg}"
      tDiv:
        "arg1 is {arg1}"
      tDiv:
        "arg2 is {arg2}"
      tDiv:
        "arg3 is {arg3}"
      tDiv:
        "arg4 is \"{arg4}\""
  
  get "/issue217/{p:path=filename}":
    return p
  
  get "/issue219/{p:path=/}":
    return p
  
  ws "/ws":
    await wsClient.send("hello")

  wsConnect:
    echo "New connection!"
    await wsClient.send("You're welcome!")
  
  wsMismatchProtocol:
    echo "mismatch protocol"
  
  wsClosed:
    echo "connect is closed"
  
  wsError:
    echo "unknown WS error"
