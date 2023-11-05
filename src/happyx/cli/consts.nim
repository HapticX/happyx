
const
  configString* = """# HappyX project configuration.

[Main]
projectName = {projectName}
projectType = {projectTypes[selected]}
mainFile = main  # main script filename (without extension) that should be launched with hpx dev command
srcDir = src  # source directory in project root
buildDir = build  # build directory in project root
assetsDir = public  # assets directory in srcDir, will copied into build/public
language = {lang}  # programming language
"""
  readmeTemplate* = """<div align="center">

# {projectName}

### {projectTypes[selected]} project written in HappyX with ❤

</div>
"""
  nimGitignore* = """# Nimcache
nimcache/
cache/
build/

# Garbage
*.exe
*.js
*.log
*.lg
"""
  pyGitignore* = """# Python cache
__pycache__/
build/

# Logs
*.log
*.lg
"""
  nodeGitignore* = """# Node cache
node_modules/
package-lock.json
yarn.lock
"""
  typescriptConfig* = """{
  "compilerOptions": {
    "moduleDetection": "auto",
    "target": "ES6",
    "module": "CommonJS",
    "outDir": "./build",
    "rootDir": "./src",
    "checkJs": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noPropertyAccessFromIndexSignature": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitReturns": true,
    "noImplicitAny": false,
    "strict": true,
    "noEmit": false,
    "allowJs": true
  }
}
"""
  packageJson* = """"{{
  "name": "happyx-project",
  "description": "Yet another NodeJS HappyX project",
  "version": "1.0.0",
  "author": "{username}",
  "type": "module",
  "main": "src/index.js",
  "keywords": [],
  "license": "MIT",
  "dependencies": {{
    "happyx": "^1.0.8",
    "typescript": "^5.2.2"
  }}
}}
"""
  nimjaTemplate* = """<!DOCTYPE html><html>
  <head>
    <meta charset="utf-8">
    <title>{{ title }}</title>
  </head>
  <body>
    You at {{ title }} page ✨
  </body>
</html>"""
  ssrTemplateNinja* = """# Import HappyX
import
  {imports.join(",\n  ")}

# Declare template folder
templateFolder("templates")

proc render(title: string): string =
  ## Renders template and returns HTML string
  ## 
  ## `title` is template argument
  renderTemplate("index.html")

# Serve at http://127.0.0.1:5000
serve("127.0.0.1", 5000):
  # on GET HTTP method at http://127.0.0.1:5000/TEXT
  get "/{{title:string}}":
    req.answerHtml render(title)
  # on any HTTP method at http://127.0.0.1:5000/public/path/to/file.ext
  staticDir "public"
"""
  ssrTemplate* = """# Import HappyX
import
  {imports.join(",\n  ")}

# Serve at http://127.0.0.1:5000
serve("127.0.0.1", 5000):
  # on GET HTTP method at http://127.0.0.1:5000/
  get "/":
    # Return plain text
    "Hello, world!"
  # on any HTTP method at http://127.0.0.1:5000/public/path/to/file.ext
  staticDir "public"
"""
  pyTemplate* = """# Import HappyX
from happyx import new_server, HttpRequest


# Just run python file to serve at http://localhost:5000
app = new_server('127.0.0.1', 5000)


# on GET method at http://localhost:5000/
@app.get('/')
def home():
    # Just return any data ✌
    return 'Hello, world!'

"""
  jsTemplate* = """// Import HappyX
import { Server } from "happyx";


const app = new Server("127.0.0.1", 5000);


// Register GET route at http://127.0.0.1:5000/
app.get("/", (req) => {
  return "Hello, world!";
});


// start app
app.start();
"""
  tsTemplate* = """// Import HappyX
import { Server, Request } from "happyx";


const app = new Server("127.0.0.1", 5000);


// Register GET route at http://127.0.0.1:5000/
app.get("/", (req: Request) => {
  return "Hello, world!";
});


// start app
app.start();
"""
  spaTemplate* = """# Import HappyX
import
  {imports.join(",\n  ")}

# Declare application with ID "app"
appRoutes("app"):
  "/":
    # Component usage
    component HelloWorld
"""
  spaServiceWorkerTemplate* = """
const web_cache = "web-app-cache-v1.0";
const filesToCache = [
  "/",
  "/main.js"
];

self.addEventListener('install', (event)=> {
  event.waitUntil(
    caches.open(web_cache)
      .then((cache)=> {
        //Cache has been opened successfully
        return cache.addAll(filesToCache);
      })
  );
});
"""
  spaIndexTemplate* = """<!DOCTYPE html><html>
  <head>
    <meta charset="utf-8">
    <title>{projectName}</title>
    {additionalHead}
  </head>
  <body>
    <div id="app"></div>
    <script src="{SPA_MAIN_FILE}.js"></script>
  </body>
</html>"""
  spaPwaManifest* = """{{
  "name": "{projectName}",
  "short_name": "{projectName}",
  "display": "fullscreen",
  "orientation": "portrait",
  "start_url": "https://hapticx.github.io/happyx/#/",
  "icons": [
    {{
      "src": "https://hapticx.github.io/happyx/public/icon.png",
      "sizes": "200x200",
      "type": "image/png"
    }}
  ]
}}"""
  spaPwaIndexTemplate* = """<!DOCTYPE html><html>
  <head>
    <meta charset="utf-8">
    <title>{projectName}</title>
    <link rel="manifest" href="manifest.json" />
    {additionalHead}
  </head>
  <body>
    <div id="app"></div>
    <script src="{SPA_MAIN_FILE}.js"></script>
    <script>
      if ('serviceWorker' in navigator) {{
        window.addEventListener('load',()=> {{
          navigator.serviceWorker.register('/service_worker.js');
        }});
      }}
    </script>
  </body>
</html>"""
  componentTemplate* = """# Import HappyX
import happyx


# Declare component
component HelloWorld:
  # Declare HTML template
  `template`:
    tDiv(class = "someClass"):
      "Hello, world!"
  `script`:
    echo "Start coding!"
"""
  hpxTemplate* = """<template>
  <div>
    <HelloWorld userId:int="10" query="meow" pathParam="Path Param Example"></HelloWorld>
  </div>
</template>
"""
  hpxComponentTemplate* = """<template>
  <div>
    Hello, world! {self.userId}
    <p>
      Query is
      {self.query}
    </p>
    <p>
      pathParam is
      {self.pathParam}
    </p>
  </div>
</template>


<script>
echo "Hello, world!"
props:
  userId: int = 0
  query: string = ""
  pathParam: string = ""
</script>

<style>
  .div {
    border-radius: 4px;
    background-color: #212121;
    color: #ffffff;
  }
</style>
"""
  hpxRouterTemplate* = """{
  "/": "main.hpx",
  "/user{ARG1:int}/{ARG2?:string}": {
    "component": "HelloWorld",
    "args": {
      "userId": "ARG1",
      "query": {
        "name": "q",
        "type": "query"
      },
      "pathParam": {
        "name": "ARG2",
        "type": "pathParam"
      }
    }
  }
}
"""
