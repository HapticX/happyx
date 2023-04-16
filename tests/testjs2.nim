import ../src/happyx


# Create a new app
var
  app = newApp()

app.routes:
  "/":
    "Hello, world!"
    button:
      "Go to /visit"
      @click:
        echo "Clicked!"
        app.route("/visit")

  "/visit":
    script(src="https://cdn.tailwindcss.com")  # Tailwind CSS :D
    tDiv(class="bg-gray-700 text-pink-400 px-8 py-24"):
      "This page visited 0 times"
    button:
      "Go to /visit"
      @click:
        echo "Clicked!"
        app.route("/visit")
    button:
      "Go to /"
      @click:
        app.route("/")
    button:
      "Go to /calc"
      @click:
        app.route("/calc5+5")

  "/calc{left:int}{op:/[\\+\\-]/}{right:int}":
    h1:
      "Result of {left} {op} {right}"
    h2:
      if op == "+":
        {left + right}
      else:
        {left - right}
    button:
      "Go to /visit"
      @click:
        echo "Clicked!"
        app.route("/visit")
  
  "/shop":
    echo "When statement list ends with buildHtml macro you can use Nim"
    let someArg = 0
    buildHtml:
      "Like this"
      {someArg}

  notfound:
    class = "myClass"
    "Oops! Not found!"

app.start()
