import
  ../src/happyx,
  components/[main, hello_world]


app.routes:
  "/":
    component HelloWorld(counter = 1.0)
    component HelloWorld(counter = 2.0)
    component HelloWorld(counter = 4.0)
    component HelloWorld(counter = 8.0)
    component HelloWorld(counter = 16.0)

  "/visit":
    script(src="https://cdn.tailwindcss.com")  # Tailwind CSS :D
    tDiv(class="bg-gray-700 text-pink-400 px-8 py-24"):
      "This page was visited"
    button:
      "Go to /visit"
      @click:
        echo "Clicked!"
        route("/visit")
    button:
      "Go to /"
      @click:
        route("/")
    button:
      "Go to /calc"
      @click:
        route("/calc5+5")

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
        route("/visit")
  
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
