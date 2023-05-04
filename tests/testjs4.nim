import ../src/happyx


var
  app = registerApp()
  darkMode = remember false

app.routes:
  "/":
    if darkMode:
      tDiv(class="bg-gray-900 text-white px-8 py-24"):
        "This page was visited"
    else:
      tDiv(class="bg-gray-200 text-black px-8 py-24"):
        "This page was visited"
    button:
      "Toggle dark mode"
      @click:
        darkMode.val = not darkMode
        echo darkMode

app.start()
