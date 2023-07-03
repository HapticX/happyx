# Import HappyX
import
  happyx,
  ../ui/colors,
  ./button


# Declare component
component Header:
  # Declare HTML template
  `template`:
    tDiv(class = "flex justify-between items-center px-8 py-2 backdrop-blur-sm h-fit"):
      tDiv:  # logo
        tImg(src = "/public/logo.svg", class = "h-12")
        @click:
          route("/")
      tDiv(class = "flex gap-2 h-full"):  # buttons
        component Button(flat = true):
          "Blog"
        component Button(
          action = proc() =
            route("/docs")
        ):
          "Docs"
