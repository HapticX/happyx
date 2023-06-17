import
  ../src/happyx,
  components/[component_js_css]



appRoutes("app"):
  "/":
    component Pure
    nim:
      var x = 0
    while x <= 20:
      tDiv:
        "Hello, {x}th world!"
      nim:
        if x == 6:
          x *= 2
          continue
        x += 2
