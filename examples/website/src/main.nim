# Import HappyX
import
  ../../../src/happyx,
  ./path_params,
  ./ui/colors,
  ./components/[
    button, card, code_block, header,
    section, smart_card, about_section,
    drawer, divider, sponsors_arr
  ],
  ./pages/[home, sponsors]


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
  mount "/" -> Home
  mount "/sponsors" -> Sponsors

  notfound:
    tDiv(class = "flex flex-col gap-2 justify-center items-center w-screen h-screen dark:text-[{ForegroundDark}] text-[{Foreground}] dark:bg-[{BackgroundDark}] bg-[{Background}]"):
      tP(class = "text-9xl font-semibold"):
        "404"
      tP(class = "text-xl font-semibold"):
        "Oops! Not found"
      
    tDiv(class = "flex flex-col justify-end items-center absolute top-0 left-0 bottom-24 right-0 upper"):
      component Button(
        action = proc() =
          route("/")
      ):
        "go to home"
    
    tStyle: """
      @keyframes upper-anim {
        0% {
          opacity: 0;
          transform: translateY(50px);
        }
        100% {
          opacity: 1;
          transform: translateY(0);
        }
      }

      .upper {
        animation: upper-anim .5s cubic-bezier(.57,-0.05,.85,.43)
      }
    """
