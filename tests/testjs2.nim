import ../src/happyx


# Create a new app
var
  app = newApp()

app.routes:
  "/":
    echo path
    buildHtml(`div`):
      "Hello, world!"

  "/visit":
    buildHtml(tDiv):
      script(src="https://cdn.tailwindcss.com")  # Tailwind CSS :D
      tDiv(class="bg-gray-700 text-pink-400 px-8 py-24"):
        "This page visited 0 times"
      button:
        "Click for increase"
        @click:
          echo "Clicked!"

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

  notfound:
    buildHtml(tDiv):
      class = "myClass"
      "Oops! Not found!"

app.start()
