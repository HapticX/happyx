import ../src/happyx


type
  TestEnum = enum
    teOne,
    teTwo,
    teThree,
    teFour,
    teFive


var
  state = remember true
  state1 = remember 1
  state2 = remember @["h1", "h2", "h3", "h4", "h5", "h6"]
  state3 = teTwo

var html =
  buildHtml(`div`):
    !DOCTYPE html
    tH1(class="myClass", style="color: red"):
      "Hello, world!"
    # Different styles of tag naming
    # <h1></h1>
    hH1
    tagH1
    `h1`
    if state:  # IF-ELIF-ELSE
      `div`:
        "True!"
        tButton:
          "click"
    elif state1 == 2:
      "State is 2"
    else:
      "False :("
    if state1 == 1:  # Just IF
      tH1:
        "Hello!"
    tInput(`type`="password")
    tButton:
      "click!"
    for i in state2:  # FOR STMT
      i
    `div`(style="background: red"):
      for i in state2:  # FOR STMT
        "current tag is {i}"
        {i}
    # VARIABLES
    {state}
    {state1}
    {state2}
    # CASE-OF STMT
    case state3:
    of teOne:
      tH1:
        "Hello"
    of teTwo:
      tH2:
        "Hi"
    of teThree:
      tH3:
        "Oops"
    rawHtml: """
      <div>
        <input type="password" />
        <hr>
        <script>
          var x = "Hello, world!";
        </script>
      </div>
      """
    rawHtml: """
      Hello, world!
      """

html.get("input")["class"] = "a"

echo html
