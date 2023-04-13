import ../src/happyx


# Create a new app
var app = newApp()

app.routes:
  "/":
    buildHtml(`div`):
      "Hello, world!"
  "/hello!":
    buildHtml(`div`):
      "No, bye!"

router("asd")

app.start()
