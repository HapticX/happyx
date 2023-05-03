import ../src/happyx


templateFolder("templates")

proc render(title: string, left: float, right: float): string =
  renderTemplate("index.html")


serve("127.0.0.1", 5000):
  get "/{title:string}/{left:float}/{right:float}":
    req.answerHtml render(title, left, right)
  
  get "/":
    echo query
