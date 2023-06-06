# Import HappyX
import
  happyx

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
  get "/{title:string}":
    req.answerHtml render(title)
  # on any HTTP method at http://127.0.0.1:5000/public/path/to/file.ext
  staticDir "public"

