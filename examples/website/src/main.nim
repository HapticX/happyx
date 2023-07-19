# Import HappyX
import
  happyx,
  path_params,
  components/[header, smart_card, card, section, code_block],
  ui/colors


{.emit: """//js
function clamp(min, max, value) {
  return Math.max(min, Math.min(max, value));
}

window.addEventListener('scroll', (ev) => {
  if (window.location.href.split('#')[1] != "/"){
    return
  }
  // Animate
  let children = document.getElementById("cover").children;
  for(let i = 0; i < children.length; i++) {
    let state = clamp(0, window.pageYOffset, window.pageYOffset - (100 * i)) * children.length / i;
    children[i].style.transform = 'translateY(-' + state * 0.5 + 'px)';
    children[i].style.opacity = (1.0 - state * 0.001);
  }
}, false);
""".}


# Declare application with ID "app"
appRoutes("app"):
  "/":
    # Component usage
    tDiv(class = "flex flex-col gap-2 bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      tDiv(id = "cover", class = "flex flex-col gap-2 relative justify-center items-center h-screen"):
        tImg(src = "happyx/public/cover_gradient.svg", class = "absolute h-screen w-screen object-cover pointer-events-none")
        tImg(src = "happyx/public/nim_logo.svg", class = "z-10 pointer-events-none")
        tImg(src = "happyx/public/happyx.svg", class = "z-10 pointer-events-none")
        tImg(src = "happyx/public/desc.svg", class = "z-10 pointer-events-none")
      tDiv(class = "flex flex-col gap-4"):
        tDiv(class = "sticky top-0 z-20"):
          component Header
        tDiv(class = "flex flex-col gap-16 items-center justify-center items-center w-full"):
          component SmartCard:
            component CodeBlock(source = """import happyx

serve("127.0.0.1", 5000):
  get "/":
    return "Hello, world!" """)
            tDiv(class = "w-36 xl:w-96 text-lg xl:text-base text-center subpixel-antialiased"):
              "Make server-side applications easily with powerful DSL 🔥"
          component Section:
            tP: "One of the main features of HappyX is DSL ✌."
            tP: "DSL supports:"
            tDiv(class = "flex flex-col md:flex-row gap-6 py-8"):
              component Card(pathToImg = "happyx/public/html5.svg"):
                "Buil HTML/CSS/JS"
              component Card(pathToImg = "happyx/public/setting.svg"):
                "Path Params"
              component Card(pathToImg = "happyx/public/routing.svg"):
                "Routing/Mounting"
          component SmartCard:
            component CodeBlock(source = """import happyx

appRoutes("app"):
  "/":
    "Hello, world!" """)
            tDiv(class = "w-36 xl:w-96 text-lg xl:text-base text-center subpixel-antialiased"):
              "Make powerful full-stack apps with really same syntax ⚡"
          component Section:
            tP: "You can easily and effectively create powerful modern web apps ✌"
            tP: "You'll never have to learn new web frameworks again ✨"
