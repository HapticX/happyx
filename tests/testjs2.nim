import
  ../src/happyx,
  components/[hello_world, nested_component, component_for, component_with_slot]


var app = registerApp()

var t = initTag("div", @[], true)
echo t.onlyChildren
var d = t.Node
echo d.TagRef.onlyChildren
echo cast[TagRef](d).onlyChildren

app.routes:
  "/":
    component HelloWorld(counter = 1.0)
    component HelloWorld(counter = 2.0)
    component HelloWorld(counter = 4.0)
    component HelloWorld(counter = 8.0)
    component HelloWorld(counter = 16.0)
    tagTextarea(style = "font-weight: 500; margin-bottom: 10px;"):
      "Hello, world"
  
  "/slots":
    component CompWithSlot:
      "hello, world!"
    component CompWithSlot(counter = 100):
      "Hello"
  
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
        route("/calc/5/%2b/5")  # /calc5+5

  "/calc/{left:int}/{op:string}/{right:int}":
    h1:
      "Result of {left} {op} {right}"
    h2:
      if op == "+":
        {left + right}
      else:
        {left - right}
      nim:
        echo op
        echo fmt"Hello from {path}!"
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
            echo i
      component ComponentFor(counter = 5)
      {someArg}
  
  "/asd":
    tDiv(a = "1"):
      b := "2"
      @click:
        echo 3
    tDiv:
      a := "1"
      b := "2"
      @click:
        echo 3

  notfound:
    nim:
      echo currentRoute
    class := "myClass"
    "Oops! Not found!"

app.start()
