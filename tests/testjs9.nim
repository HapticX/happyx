import
  ../src/happyx,
  components/[component_js_css]


translatable:
  "Hello":
    # "Hello!" by default
    "ru" -> "Привет"
    "fr" -> "Bonjour"


appRoutes("app"):
  "/":
    component Pure
    nim:
      var
        x = 0
        str = translate("Hello")
    while x <= 20:
      tDiv:
        "{str}, {x}th world!"
      nim:
        if x == 6:
          x *= 2
          continue
        x += 2
