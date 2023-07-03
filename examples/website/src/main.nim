# Import HappyX
import
  happyx,
  path_params,
  components/[header],
  ui/colors


{.emit: """//js
window.addEventListener('scroll', () => {
  if (window.location.href.split('#')[1] != "/")
    return
  let children = document.getElementById("cover").children;
  for(let i = 0; i < children.length; i++) {
    children[i].style.transform = 'translateY(-' + (window.pageYOffset * i / children.length) + 'px)';
  }
}, false)
""".}


# Declare application with ID "app"
appRoutes("app"):
  "/":
    # Component usage
    tDiv(class = "flex flex-col gap-2"):
      tDiv(id = "cover", class = "flex relative justify-center items-center h-screen"):
        tImg(src = "/public/cover_gradient.svg", class = "absolute h-screen w-screen object-cover pointer-events-none")
        tImg(src = "/public/cover.svg", class = "absolute z-10 pointer-events-none")
      tDiv(class = "flex flex-col gap-4 bg-[{Background}]"):
        tDiv(class = "sticky top-0"):
          component Header
        tDiv(class = "px-24"):
          for i in 0..100:
            tDiv:
              "Lorem ipsum"
