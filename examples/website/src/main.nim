# Import HappyX
import
  happyx,
  path_params,
  components/[header, smart_card, card, section],
  ui/colors


{.emit: """//js
let clamp = (min, max, value) => {
  return Math.max(min, Math.min(max, value));
}

window.addEventListener('scroll', (ev) => {
  if (window.location.href.split('#')[1] != "/")
    return
  // Animate
  let children = document.getElementById("cover").children;
  for(let i = 0; i < children.length; i++) {
    let state = clamp(0, window.pageYOffset, window.pageYOffset - (100 * i)) * children.length / i;
    children[i].style.transform = 'translateY(-' + state * 0.5 + 'px)';
    children[i].style.opacity = (1.0 - state * 0.001);
  }
}, false);

function rotate(mouseEvent, element) {
  let elemRect = element.getBoundingClientRect();
  let elemX = elemRect.left + (elemRect.right - elemRect.left) / 2.0;
  let elemY = elemRect.top + (elemRect.bottom - elemRect.top) / 2.0;
  let x = elemX - mouseEvent.pageX;
  let y = elemY + mouseEvent.pageY;
  element.style.transform = 'rotateX(' + y * 0.01 + 'deg) rotateY(' + x * 0.01 + 'deg) translatez(0) perspective(80px)';
  element.style.webkitTransform = 'rotateX(' + y * 0.01 + 'deg) rotateY(' + x * 0.01 + 'deg) translatez(0) perspective(80px)';
  element.style.transformStyle = 'preserve-3d';
}

window.addEventListener('mousemove', (ev) => {
  if (window.location.href.split('#')[1] != "/")
    return
  rotate(ev, document.getElementById("ssr"));
  rotate(ev, document.getElementById("spa"));
});
""".}


# Declare application with ID "app"
appRoutes("app"):
  "/":
    # Component usage
    tDiv(class = "flex flex-col gap-2 bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      tDiv(id = "cover", class = "flex flex-col gap-2 relative justify-center items-center h-screen"):
        tImg(src = "/happyx/public/cover_gradient.svg", class = "absolute h-screen w-screen object-cover pointer-events-none")
        tImg(src = "/happyx/public/nim_logo.svg", class = "z-10 pointer-events-none")
        tImg(src = "/happyx/public/HappyX.svg", class = "z-10 pointer-events-none")
        tImg(src = "/happyx/public/desc.svg", class = "z-10 pointer-events-none")
      tDiv(class = "flex flex-col gap-4"):
        tDiv(class = "sticky top-0 z-20"):
          component Header
        tDiv(class = "flex flex-col gap-16 items-center justify-center items-center w-full"):
          component SmartCard(id = "ssr"):
            tImg(src = "/happyx/public/ssr.png", class = "w-96 h-96 pointer-events-none select-none rounded-tl-md rounded-bl-md")
            tDiv(class = "w-96 text-center subpixel-antialiased"):
              "Make server-side applications easily with powerful DSL 🔥"
          component Section:
            tP: "One of the main features of HappyX is DSL ✌."
            tP: "DSL supports:"
            tDiv(class = "flex gap-4 py-8"):
              component Card(pathToImg = "/happyx/public/html5.svg"):
                "Buil HTML/CSS/JS"
              component Card(pathToImg = "/happyx/public/setting.svg"):
                "Path Params"
              component Card(pathToImg = "/happyx/public/routing.svg"):
                "Routing/Mounting"
          component SmartCard(id = "spa"):
            tImg(src = "/happyx/public/spa.png", class = "w-96 h-96 pointer-events-none select-none rounded-tl-md rounded-bl-md")
            tDiv(class = "w-96 text-center subpixel-antialiased"):
              "Make powerful full-stack apps with really same syntax ⚡"
          component Section:
            tP: "You can easily and effectively create powerful modern web apps ✌"
            tP: "You'll never have to learn new web frameworks again ✨"
