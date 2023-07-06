# Import HappyX
import
  happyx,
  path_params,
  components/[header],
  ui/colors


{.emit: """//js
let clamp = (min, max, value) => {
  return Math.max(min, Math.min(max, value));
}

window.addEventListener('scroll', () => {
  if (window.location.href.split('#')[1] != "/")
    return
  let children = document.getElementById("cover").children;
  for(let i = 0; i < children.length; i++) {
    let state = clamp(0, window.pageYOffset, window.pageYOffset - 50) * children.length / i;
    children[i].style.transform = 'translateY(-' + state * 0.5 + 'px)';
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
    tDiv(class = "flex flex-col gap-2"):
      tDiv(id = "cover", class = "flex flex-col gap-2 relative justify-center items-center h-screen"):
        tImg(src = "/happyx/public/cover_gradient.svg", class = "absolute h-screen w-screen object-cover pointer-events-none")
        tImg(src = "/happyx/public/nim_logo.svg", class = "z-10 pointer-events-none")
        tImg(src = "/happyx/public/HappyX.svg", class = "z-10 pointer-events-none")
        tImg(src = "/happyx/public/desc.svg", class = "z-10 pointer-events-none")
      tDiv(class = "flex flex-col gap-4 bg-[{Background}]"):
        tDiv(class = "sticky top-0 z-20"):
          component Header
        tDiv(class = "flex flex-col gap-16 items-center justify-center items-center w-full"):
          tDiv(id = "ssr", class = "flex will-change-transform justify-center items-center gap-12 w-fit drop-shadow-2xl rounded-md bg-white"):
            tImg(src = "/happyx/public/ssr.png", class = "w-96 h-96 pointer-events-none select-none rounded-tl-md rounded-bl-md drop-shadow-2xl")
            tDiv(class = "w-96 text-center subpixel-antialiased"):
              "Make server-side applications easily with powerful DSL 🔥"
          tDiv(class = "flex flex-col bg-[{BackgroundSecondary}] w-full px-96 py-36"):
            tP: "One of the main features of HappyX is DSL ✌."
            tP: "DSL supports:"
            tUl(class = "list-disc px-2 list-inside indent-2"):
              tLi: "Build HTML 🔥"
              tLi: "Build CSS 🎴"
              tLi: "Build JavaScript code 🔨"
              tLi: "Request models ⚙"
              tLi: "Path params 🛠"
              tLi: "Mounting 🔌"
              tLi: "App logic ✨"
          tDiv(id = "spa", class = "flex will-change-transform justify-center items-center gap-12 w-fit drop-shadow-2xl rounded-md bg-white"):
            tImg(src = "/happyx/public/spa.png", class = "w-96 h-96 pointer-events-none select-none rounded-tl-md rounded-bl-md drop-shadow-2xl")
            tDiv(class = "w-96 text-center subpixel-antialiased"):
              "Make powerful full-stack apps with really same syntax ⚡"
          tDiv(class = "flex flex-col bg-[{BackgroundSecondary}] w-full px-96 py-36"):
            tP: ""
