import ../src/happyx


# Create a new app
var
  app = newApp()

app.routes:
  "/":
    echo path
    buildHtml(`div`):
      "Hello, world!"
      button:
        "Go to /visit"
        @click:
          echo "Clicked!"
          app.route("/visit")

  "/visit":
    buildHtml(tDiv):
      script(src="https://cdn.tailwindcss.com")  # Tailwind CSS :D
      tDiv(class="bg-gray-700 text-pink-400 px-8 py-24"):
        "This page visited 0 times"
      button:
        "Go to /visit"
        @click:
          echo "Clicked!"
          app.route("/visit")
      button:
        "Go to /"
        @click:
          app.route("/")
      button:
        "Go to /calc"
        @click:
          app.route("/calc5+5")

  "/calc{left:int}{op:/[\\+\\-]/}{right:int}":
    echo op
    buildHtml(`div`):
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
          app.route("/visit")

  notfound:
    buildHtml(tDiv):
      class = "myClass"
      "Oops! Not found!"

app.start()
