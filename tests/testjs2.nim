import ../src/happyx


# Create a new app
var app = newApp()

app.routes:
  "/":
    echo path
    buildHtml(`div`):
      "Hello, world!"
  "/calc{left:int}{op:/[\\+\\-]/}{right:int}":
    echo op
    buildHtml(`div`):
      h1:
        "Result of {left} {op} {right}"
      h2:
        if op == "+":
          {left + right}
        else:
          {left - right}
  notfound:
    buildHtml(tDiv):
      class = "myClass"
      "Oops! Not found!"

app.start()
