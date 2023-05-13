import
  ../src/happyx,
  components/[hello_world, nested_component, component_for]


var app = registerApp()

app.routes:
  "/":
    component HelloWorld(counter = 1.0)
    component HelloWorld(counter = 2.0)
    component HelloWorld(counter = 4.0)
    component HelloWorld(counter = 8.0)
    component HelloWorld(counter = 16.0)
  
  "/nested":
    component NestedComponent2

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
      for i in 0..10:
        tButton(id="{i}", asd="123", class="rounded-full px-16 py-1 my-1 bg-gray-200 hover:bg-gray-300 transition-colors"):
          {i}
          @click:
            echo document.getElementById(fmt"{i}").innerHTML
            echo i
      component ComponentFor(counter = 5)
      {someArg}

  notfound:
    class = "myClass"
    "Oops! Not found!"

app.start()