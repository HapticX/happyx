import ../src/happyx


# Create a new app
var app = newApp()

app.routes:
  "#/":
    echo path
    buildHtml(`div`):
      "Hello, world!"
  "#/hello!":
    buildHtml(`div`):
      "No, bye!"

app.start()
