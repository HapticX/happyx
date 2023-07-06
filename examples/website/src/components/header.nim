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
        tImg(src = "/happyx/public/logo.svg", class = "h-12")
        @click:
          route("/")
      tDiv(class = "flex gap-2 h-full"):  # buttons
        component Button(
          action = proc() =
            {.emit:"""//js
            window.open('https://github.com/HapticX/happyx', '_blank').focus();
            """.}
        ):
          tDiv(class = "flex items-center gap-4"):
            tImg(src = "/happyx/public/git.svg", class = "h-6 w-6")
            tP: "Source code"
        component Button(
          action = proc() =
            {.emit: """//js
            window.open('https://hapticx.github.io/happyx/happyx.html', '_blank').focus();
            """.}
        ):
          "API Docs"
