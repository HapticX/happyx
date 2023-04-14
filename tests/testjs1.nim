import ../src/happyx


var state = remember true
var state1 = remember 1
var state2 = remember @["h1", "h2", "h3", "h4", "h5", "h6"]

var html =
  buildHtml(`div`):
    h1(class="myClass", style="color: red"):
      "Hello, world!"
    # Different styles of tag naming
    # <h1></h1>
    hH1
    tagH1
    `h1`
    h1
    if state:  # IF-ELIF-ELSE
      `div`:
        "True!"
        button:
          "click"
    elif state1 == 2:
      "State is 2"
    else:
      "False :("
    if state1 == 1:  # Just IF
      h1:
        "Hello!"
    input(`type`="password")
    button:
      "click!"
    for i in state2:  # FOR STMT
      i
    `div`(style="background: red"):
      for i in state2:  # FOR STMT
        i(attr="{i}{i}{i}"):
          "current tag is {i}"
          {i}
    {state}
    {state1}
    {state2}

html.get("input")["class"] = "a"

echo html
