## # HappyX
## 
##   ### Web framework written in Nim with ❤
## 
## 
## ## Why HappyX? 🤔
## HappyX is SPA/SSG web framework that provides same syntax in both parts of framework (SPA and SSG).
## - SPA part provides `components` and powerful state management.
## - SSG part provides `buildHtml`.
## 
## SPA and SSG also provides both syntax for routing.
## You don't need to learn new syntax for new projects.
## 
## HappyX provides CLI tool for creating and serving your projects 🛠
## 
## Create new project ✨
## ```bash
## hpx create
## ```
## 
## Serve existing SPA project 🛠
## ```bash
## hpx dev
## ```
## 
## Help ❔
## ```bash
## hpx help [subcommand]
## ```
## 
## 
## ## Examples
## 
## ### SPA
## 
## SPA works only on JS backend
## 
## - `index.html`
## 
##   .. code-block::html
##      <html>
##        <head>
##          <meta charset="utf-8">
##          <title>Title</title>
##        </head>
##        <body>
##          <div id="app"></div>
##          <script src="main.js"></script>
##        </body>
##      </html>
## 
## - `components/hello_world.nim`
## 
##   .. code-block::nim
##      import happyx
##      
##      component HelloWorld:
##        `template`:
##          tDiv:
##            "Hello, world!"
##        `script`:
##          discard
##        `style`:
##          """
##          div {
##            color: green;
##          }
##          """
## 
## - `main.nim`
## 
##   .. code-block::nim
##      import
##        happyx,
##        components/[hello_world]
##      
##      var app = registerApp()
##      
##      app.routes:
##        "/":
##          component HelloWorld
##      
##      app.start()
## 
## 
## ### SSG
## 
## SSG works only on C/Cpp/ObjC backends
## 
## - `main.nim`
## 
##   .. code-block::nim
##      import happyx
##      
##      serve("127.0.0.1", 5000):
##        get "/":
##          # available only on GET method
##          "Hello, world"
##        
##        "/framework":
##          req.answer "This method available from any method (POST, GET, PUT, etc.)"
##        
##        middleware:
##          echo "This will printed first"
##        
##        notfound:
##          req.answer "Oops, not found!"
## 
## ### CLI Usage
## 
## #### SSG
## 
## At first we need to create project and choose SSG project type.
## ```bash
## hpx create
## ```
## 
## This creates directory with `.gitignore`, `README.md` and `main.nim` files
## 
## After creating you can work with project as you want
## 
## #### SPA
## 
## At first we need to create project and choose SPA project type.
## ```bash
## hpx create
## ```
## 
## This creates directory with `.gitignore`, `README.md`, `main.nim` and `components/hello_world.nim` files
## 
## After creating you can work with project as you want
## ```bash
## cd PROJECT_NAME
## hpx dev
## ```
## 
## `hpx dev` command will see all changes in your project and recompile `main.nim`
## 
## `hpx build` command will builds your project as standalone web application (HTML + JS files)
## 
## 
when not defined(js):
  import
    happyx/ssg/[server]

  export
    server

import
  happyx/spa/[renderer, state],
  happyx/tmpl_engine/[engine]

export
  renderer,
  state,
  engine
