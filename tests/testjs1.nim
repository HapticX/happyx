import ../src/happyx


var state = true

var html =
  buildHtml(`div`):
    h1(class="myClass", style="{color:red}"):
      "Hello, world!"
    `div`:
      h5:
        "Hello, world!"
      h6:
        "Hello, world!"
    if state:
      "True!"
    else:
      "False :("
    input(`type`="password")
    button:
      "click!"

html.get("input")["class"] = "a"

echo html
