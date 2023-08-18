var
  ssrExample* = """import happyx

serve "127.0.0.1", 5000:
  get "/":
    return "Hello, world!"
"""
  spaExample* = """import happyx

appRoutes "app":
  "/":
    "Hello, world!"
"""
  fileResponseExample* = """import happyx

server "127.0.0.1", 5000:
  "/":
    return FileResponse("image.png")
"""
  pathParamsSsrExample* = """import happyx

server "127.0.0.1", 5000:
  "/user{id:int}":
    return fmt"Hello! user {id}"
"""
  pathParamsSpaExample* = """import happyx

appRoutes "app":
  "/user{id:int}":
    "Hello! user {id}"
"""

  nimSsrHelloWorldExample* = """import happyx

# Serve app at http://localhost:5000
serve "127.0.0.1", 5000:
  # GET Method
  get "/":
    # Respond plaintext
    return "Hello, world"
"""

  nimSpaHelloWorldExample* = """import happyx

# Serve app at http://localhost:5000
appRoutes "app":
  # at example.com/#/
  "/":
    # plaintext
    "Hello, world"
"""

  pythonHelloWorldExample* = """from happyx import new_server

# Create application
app = new_server('127.0.0.1', 5000)


# GET method
@app.get('/')
def hello_world():
    # Respond plaintext
    return 'Hello, world!'


# start our app
app.start()
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

  nimProjectSsr* = """project/
├─ src/
│  ├─ templates/
│  │  ├─ index.html
│  ├─ public/
│  │  ├─ icon.svg
│  ├─ main.nim
├─ README.md
├─ .gitignore
├─ happyx.cfg
├─ project.nimble
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

  pythonProject* = """project/
├─ main.py
├─ README.md
├─ .gitignore
"""
