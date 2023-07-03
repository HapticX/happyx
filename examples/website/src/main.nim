# Import HappyX
import
  happyx,
  path_params,
  components/[header],
  components/colors


# Declare application with ID "app"
appRoutes("app"):
  "/":
    # Component usage
    tDiv(class = "flex flex-col gap-2"):
      tDiv(id = "cover", class = "flex relative justify-center items-center h-screen"):
        tImg(src = "/public/cover_gradient.svg", class = "absolute h-screen w-screen object-cover")
        tImg(src = "/public/cover.svg", class = "z-10")
      tDiv(class = "bg-[{Background}]"):
        tDiv(class = "px-24"):
          for i in 0..100:
            tDiv:
              "Lorem ipsum"
    tScript(`type` = "text/javascript"): """
      const cover = document.getElementById("cover");
      window.addEventListener("wheel", event => {
          cover.style.top = event.deltaY
      });
      """
