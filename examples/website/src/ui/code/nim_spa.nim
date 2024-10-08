import std/strformat

const
  quotes = "\"\"\""
  spaExample* = """import happyx

appRoutes "app":
  "/":
    "Hello, world!"
"""
  pathParamsSpaExample* = """import happyx

appRoutes "app":
  "/user{id:int}":
    "Hello! user {id}"
"""
  nimSpaHelloWorldExample* = """import happyx

# Serve app at http://localhost:5000
appRoutes "app":
  # at example.com/#/
  "/":
    # plaintext
    "Hello, world"
"""
  htmlHelloWorldExample* = """<!DOCTYPE html>
<html>
  <head>
    <title>Hello World App</title>
  </head>
  <body>
    <div id="app">
      <!-- Here will be your application -->
    </div>
    <!-- Nim script after compilation -->
    <script src="example.js"></script>
  </body>
</html>
"""
  nimProjectSpa* = """project/
├─ src/
│  ├─ public/
│  │  ├─ icon.svg
│  ├─ components/
│  │  ├─ hello_world.nim
│  ├─ main.nim
│  ├─ index.html
├─ README.md
├─ .gitignore
├─ happyx.cfg
├─ project.nimble
"""
  nimSpaCalc* = """appRoutes "app":
  "/calc/{left:float}/{op}/{right:float}":
    tDiv(class = "flex text-4xl justify-center items-center w-screen h-screen text-orange-200 bg-neutral-900"):
      if op == "add":
        {left + right}
      elif op == "sub":
        {left - right}
      elif op == "del":
        {left / right}
      elif op == "mul":
        {left * right}
      else:
        "failure"
"""
  nimPathParamsSpa* = """appRoutes "app":
  "/user/id{userId:int}":
    ## here we can use userId as immutable variable
    tDiv:
      {userId}
"""
  nimAssignRouteParamsSpa* = """import happyx

# declare path params
pathParams:
  paramName int:  # assign param name
    optional  # param is optional
    mutable  # param is mutable variable
    default = 100  # default param value is 100


appRoutes "app":
  # Use paramName
  "/<paramName>":
    echo paramName
"""
  nimSpaRouting* = """import happyx


appRoutes "app":
  "/":
    "Welcome to home!"
    tButton:
      "go to '/bye'"
      @click:
        # When button clicked you'll redirect to /bye route
        route("/bye")
  "/bye":
    "Goodbye!"
"""
  nimSpaHtmlTailwind* = """<!doctype html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <!-- You just should to include Tailwind via CDN! -->
  <!-- https://tailwindcss.com/docs/installation/play-cdn -->
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body>
  <div id="app"></div>
  <script src="main.js"></script>
</body>
</html>
"""
  nimSpaTailwind* = """import happyx


appRoutes "app":
  "/":
    tH1(class = "text-3xl font-bold underline"):
      "Hello, world!"
"""
  tailwindCli* = """hpx create --name:htmx_example --kind:SSR --templates --language:Nim
cd htmx_example
npm init
npm install -D tailwindcss
npx tailwindcss init
"""
  tailwindConfig* = """/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,htmx,nim,js}"],
  theme: {
    extend: {},
  },
  plugins: [],
}"""
  tailwindCssInput* = """@tailwind base;
@tailwind components;
@tailwind utilities;"""
  tailwindWatch* = "npx tailwindcss -i ./src/public/input.css -o ./src/public/output.css --watch"
  nimSpaReactivity* = """import happyx

# Create a new state
var x = remember 0


appRoutes "app":
  "/":
    "x value is {x}"
    tButton:
      "click me to increase"
      @click:
        # change state and rerender this
        x += 1
"""
  nimSpaComponentReactivity* = """import happyx


# create component
component Test:
  x: int = 0  # component state with default value
  `template`:
    "x value is {self.x}"
    tButton:
      "click me to increase"
      @click:
        # change state and rerender this
        self.x += 1


appRoutes "app":
  "/":
    # use components
    Test(x = 10)
    Test(x = 15)
    Test(x = 20)
"""
  nimSpaReactivity1* = """import happyx

var x = remember 0

appRoutes "app":
  "/":
    tDiv:
      "x counter: {x}"
      @click:
        x->inc()
"""
  nimSpaReactivity2* = """import happyx

var x = remember newSeq[int]()

appRoutes "app":
  "/":
    tDiv:
      "x sequence is {x}"
      @click:
        x->add(x.len())
"""
  nimSpaReactivity3* = """import happyx

var
  x = remember newSeq[int]()
  y: State[seq[int]] = remember @[]
  z: State[int]
  w: State[string] = remember "Hello"
"""
  nimSpaReactivity4* = """import happyx

var
  x = remember 0
  y = 10
  str = remember "Hello"

x += y
echo x  # 10, but x is still State[int]

x *= y
echo x  # x is 100 and again, x is State[int]

str &= ", world!"
echo str  # Hello, world!, but str is State[string]
"""
  nimSpaReactivity5* = """import happyx

var
  x = remember seq[int].default

x.set @[1, 2, 3]
"""
  nimSpaComponentButton* = """import happyx

component Button:
  value: int = 0
  html:
    tButton:
      "counter {self.value}"
      @click:
        self.value += 1
"""
  nimSpaComponentsProps* = """import happyx

component Button:
  value: int  # this property should be passed anyway
  age: int = 18  # This property can be omitted
  *name: string = "Mike"  # This property can be accessed externally
  
  # You can also omit adding the component body. it's not prohibited.
"""
  nimSpaComponentsSlot* = """import happyx

component Button:
  html:
    tDiv(class = " ... "):
      slot  # your HTML will be placed here
"""
  nimSpaComponentsUse* = """
appRoutes "app":
  "/":
    Button:
      "Click me"
"""
  nimSpaComponentsScopedStyle* = fmt"""import happyx

component Button:
  color: string = "#d09dcd"

  html:
    tButton:
      "Click me"
  
  `style`: {quotes}
    button {{
      background-color: <self.color>;
    }}
  {quotes}
"""
  nimSpaComponentsScript* = fmt"""import happyx

component Button:
  html:
    tButton:
      "Click me"
  
  `script`:
    echo "Hello from Button component :)"
"""
  nimSpaFuncComp1* = fmt"""import happyx

proc MyFuncComponent*(): TagRef =
  echo "render functional component"
  buildHtml:
    "Hello from functional component"
"""
  nimSpaFuncComp2* = """import happyx

proc MyFuncComponent*(i: int, stmt: TagRef): TagRef =
  buildHtml:
    tDiv:
      "value of i is {i}"
      stmt  # slot will be rendered here
"""
  nimSpaFuncComp3* = """
appRoutes "app":
  "/":
    MyFuncComponent(100):
      "see! this is a slot"
"""
  nimSpaRendering* = """import happyx

var counter = remember 0

appRoutes "app":
  "/":
    "Now counter is {counter}."
    tButton:
      "increase counter"
      @click:
        counter += 1
    tButton:
      "go to other route"
      route "/other"
  
  "/other":
    "Hey, counter is still {counter}"
    tButton:
      "go back"
      @click:
        route "/"
"""
  nimSpaMounting* = """import happyx

mount Profile:
  "/":
    "Hello from /profile/"
  "/{id:int}":
    "Hello, user {id}! Route is /profile/{id}"
  "/settings":
    "Hello from /profile/settings"

appRoutes "app":
  mount "/profile" -> Profile
"""
  nimSpaMountingSugar* = """import happyx

"/profile/id{id:int}" -> get:
  "Hello, user id{id}"

appRoutes "app":
  discard
"""
  nimHpxTemplateExample* = """<template>
  <div>
    Hello, world!
    <div h-if="5 > 2">
      omg, 5 is larger than 2
    </div>
    <div h-elif="2 < 5">
      5 is less than 2??????
    </div>
    <div h-else>
      why math isn't working lol
    </div>
    <div h-for="i in [0, 1, 2, 3]" >
      { i }
    </div>
    <script>
      # Here you can use Nim, not JS
      var x = 0
    </script>
    <div h-while="x < 10">
      Now x is { x }
      <script>x += 1</script>
    </div>
  </div>
</template>"""
  nimHpxCreateProjectExample* = """hpx create --name hpx_project --kind HPX
cd hpx_project"""
  nimHpxScriptExample* = """<script>
  proc myFunc(): string =
    echo "Hello, world!"
    return "ok man"

  echo myFunc()
</script>"""
  nimHpxScriptExample_1* = """<template>
  <div>
    output of myFunc() is { myFunc() }
  </div>
</template>"""
  nimHpxScriptJsExample* = """<script>
  proc myFunc(): cstring {.exportc.} =
    return "ok man"
</script>

<script lang="js">
  console.log("call nim: ", myFunc());
</script>"""
  nimHpxStyleExample* = """<style>
  div {
    background-color: #212121;
    color: #cfeced;
    padding: 0.25rem;
  }
</style>"""
  nimHpxEventsExample* = """<template>
  <div>
    <button h-onclick="handleClick(event)">
      Click me!
    </button>
    <!-- input should be closable in .hpx files -->
    <input h-oninput="handleInput(event)" />
  </div>
</template>

<script>
  proc handleClick(ev: Event) =
    echo "button was clicked!"
  proc handleInput(ev: Event) =
    echo ev.target.InputElement.value
</script>"""
  nimHpxMainHpxExample* = """<template>
  <div>
    This is main page
    <HelloWorld></HelloWorld>
    <HelloWorld />
  </div>
</template>
"""
  nimHpxComponentsHelloWorldExample* = """<template>
  <div>
    Hello, world!
  </div>
</template>
"""
  nimHpxRouterExample* = """{
  /* route path */
  "/": "main",  /* just component name */
  /* route path */
  /* ex. /user7/asd */
  "/user$id:int/$test?": {
    /* just component name */
    "component": "User",
    /* arguments is component props */
    "args": {
      /* prop name: path param name */
      "userId": "id",
      /* query is query param named q */
      "query": {"name": "q", "type": "query"},
      /* pathParam is path param named test */
      "pathParam": {"name": "test", "type": "pathParam"}
    }
  }
}"""
