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
    tDiv:
      "Hello"
    nim:
      var
        x = 0
        str = translate("Hello")
    tDiv(class = "flex flex-col gap-2"):
      while x <= 20:
        tDiv(class = "flex gap-2"):
          tDiv(class = "rounded-lg bg-white drop-shadow-md px-4"):
            "{str}, {x}th world!"
          tDiv(class = "rounded-lg bg-white drop-shadow-md px-4"):
            """{str}, {x}th world!"""
        nim:
          if x == 6:
            x *= 2
            continue
          x += 2
