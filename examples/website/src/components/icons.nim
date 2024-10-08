import
  ../../../../src/happyx,
  ../ui/colors


proc svgHolder(class: string, stmt: TagRef): TagRef = buildHtml:
  tSvg("viewBox" = "0 0 24 24", "fill" = "none", "xmlns" = "http://www.w3.org/2000/svg", class = class):
    stmt


proc Crown*(class: string = ""): TagRef = buildHtml:
  svgHolder(class = class):
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M6 19L18 19")
    tPath("stroke-width" = "2", "stroke-linejoin" = "round", "d" = "M16.5585 16H7.44152C6.58066 16 5.81638 15.4491 5.54415 14.6325L3.70711 9.12132C3.44617 8.3385 4.26195 7.63098 5 8L5.71067 8.35533C6.48064 8.74032 7.41059 8.58941 8.01931 7.98069L10.5858 5.41421C11.3668 4.63317 12.6332 4.63316 13.4142 5.41421L15.9807 7.98069C16.5894 8.58941 17.5194 8.74032 18.2893 8.35533L19 8C19.7381 7.63098 20.5538 8.3385 20.2929 9.12132L18.4558 14.6325C18.1836 15.4491 17.4193 16 16.5585 16Z")


proc Code*(class: string = ""): TagRef = buildHtml:
  svgHolder(class = class):
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "d" = "M11 16L13 8")
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M17 15L19.6961 12.3039V12.3039C19.8639 12.1361 19.8639 11.8639 19.6961 11.6961V11.6961L17 9")
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M7 9L4.32151 11.6785V11.6785C4.14394 11.8561 4.14394 12.1439 4.32151 12.3215V12.3215L7 15")


proc Stars*(class: string = ""): TagRef = buildHtml:
  svgHolder(class = class):
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M21 12.1818L16.9354 13.6599C16.3462 13.8741 15.8916 14.3521 15.7073 14.9513L14.1538 20C14.1072 20.1515 13.8928 20.1515 13.8461 20L12.2927 14.9513C12.1083 14.3521 11.6537 13.8741 11.0646 13.6599L6.99999 12.1818C6.83019 12.1201 6.83019 11.8799 6.99999 11.8182L11.0646 10.3401C11.6537 10.1259 12.1083 9.64786 12.2927 9.04872L13.8461 4C13.8928 3.8485 14.1072 3.8485 14.1538 4L15.7073 9.04872C15.8916 9.64786 16.3462 10.1259 16.9354 10.3401L21 11.8182C21.1698 11.8799 21.1698 12.1201 21 12.1818Z")
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M3.75 5.25C4.22214 5.40738 4.59262 5.77786 4.75 6.25C4.83008 6.49025 5.16992 6.49025 5.25 6.25C5.40738 5.77786 5.77786 5.40738 6.25 5.25C6.49025 5.16992 6.49025 4.83008 6.25 4.75C5.77786 4.59262 5.40738 4.22214 5.25 3.75C5.16992 3.50975 4.83008 3.50975 4.75 3.75C4.59262 4.22214 4.22214 4.59262 3.75 4.75C3.50975 4.83008 3.50975 5.16992 3.75 5.25Z")
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M7.25 19.25C6.77786 19.4074 6.40738 19.7779 6.25 20.25C6.16992 20.4903 5.83008 20.4903 5.75 20.25C5.59262 19.7779 5.22214 19.4074 4.75 19.25C4.50975 19.1699 4.50975 18.8301 4.75 18.75C5.22214 18.5926 5.59262 18.2221 5.75 17.75C5.83008 17.5097 6.16992 17.5097 6.25 17.75C6.40738 18.2221 6.77786 18.5926 7.25 18.75C7.49025 18.8301 7.49025 19.1699 7.25 19.25Z")


proc Zip*(class: string = ""): TagRef = buildHtml:
  svgHolder(class = class):
    tPath("stroke-width" = "2", "stroke-linejoin" = "round", "d" = "M17.7634 10.7614L17.8704 10.5979C17.9261 10.5129 17.8651 10.4 17.7634 10.4H13.5C13.3817 10.4 13.2857 10.3041 13.2857 10.1857V4.23047V4.21257C13.2857 4.14957 13.2038 4.12513 13.1693 4.17784L7.18868 13.3118L7.10336 13.4421C7.05895 13.51 7.10761 13.6 7.18868 13.6H11.4488H11.5027C11.6196 13.6 11.7143 13.6947 11.7143 13.8116V19.6027C11.7143 19.7205 11.8683 19.7647 11.9328 19.6662L17.7634 10.7614Z")


proc ArrowRight*(class: string = ""): TagRef = buildHtml:
  svgHolder(class = class):
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M20 12L4 12")
    tPath("stroke-width" = "2", "stroke-linecap" = "round", "stroke-linejoin" = "round", "d" = "M14 18L19.9375 12.0625V12.0625C19.972 12.028 19.972 11.972 19.9375 11.9375V11.9375L14 6")
