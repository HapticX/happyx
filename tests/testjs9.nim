import
  ../src/happyx,
  components/[component_js_css]


translatable:
  "hello":
    # "Hello, $#!" by default
    "default" -> "Hello, $#!"
    "ru" -> "Привет, $#!"
    "fr" -> "Bonjour, $#!"

echo translates

appRoutes("app"):
  "/":
    component Pure
    tDiv:
      "Hello"
      {translate"nothing"}
    nim:
      var
        x = 0
        str = translate("hello", "username")
    tDiv(class = "flex flex-col gap-2"):
      while x <= 20:
        tDiv(class = "flex gap-2"):
          tDiv(class = "rounded-lg bg-white drop-shadow-md px-4"):
            "{str}, {x}th world!"
          tDiv(class = "rounded-lg bg-white drop-shadow-md px-4"):
            """{str}, {x}th world!"""
          tDiv(class = "rounded-lg bg-white drop-shadow-md px-4"):
            {fmt"""{str}, {x}th world!"""}
        nim:
          if x == 6:
            x *= 2
            continue
          x += 2
