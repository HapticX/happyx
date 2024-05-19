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
      if op == "+":
        {left + right}
      elif op == "-":
        {left - right}
      elif op == "/":
        {left / right}
      elif op == "*":
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
  nimCustomPathParamTypeSpa* = """import happyx

type MyType* = object
  first, second, third: string

proc parseMyType*(data: string): MyType =
  MyType(
    first: data[0], second: data[1], third: data[2]
  )

registerRouteParamType(
  "my_type",  # unique type identifier
  "\d\w\d",  # type pattern
  parseMyType  # proc/func that takes one string argument and returns any data
)

appRoutes "app":
  "/{i:my_type}":
    echo i.first
    echo i.second
    echo i.third
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
