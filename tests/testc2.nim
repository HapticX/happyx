import
  ../src/happyx,
  os


proc render(title: string, left: float, right: float): string =
  compileTemplateFile(getScriptDir() / "templates" / "index.html")


serve("127.0.0.1", 5000):
  get "/{title:string}/{left:float}/{right:float}":
    req.answerHtml render(title, left, right)
