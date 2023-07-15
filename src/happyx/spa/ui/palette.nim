## # Default UI Theme Palette 🎴
## 

import dom


const
  BackgroundColor* = "#0e090b"
  ForegroundColor* = "#ecedea"
  AccentColor* = "#fcff82"
  AccentHoverColor* = "#ecef72"
  AccentActiveColor* = "#dcdf62"
  SecondaryColor* = "#a8377b"
  SecondaryHoverColor* = "#98276b"
  SecondaryActiveColor* = "#88175b"


var
  body = document.getElementsByTagName("body")[0]
  styleElem = document.createElement("style")

styleElem.innerHTML = """
@import url('https://fonts.googleapis.com/css?family=Nunito');
body {
  font-family: 'Nunito', sans-serif;
  margin: 0;
  padding: 0;
}
::placeholder {
  font-family: 'Nunito', sans-serif;
  font-size: 1rem;
}
:-ms-input-placeholder {
  font-family: 'Nunito', sans-serif;
  font-size: 1rem;
}
:-moz-placeholder {
  font-family: 'Nunito', sans-serif;
  font-size: 1rem;
}
:-webkit-input-placeholder  {
  font-family: 'Nunito', sans-serif;
  font-size: 1rem;
}
"""
body.style.backgroundColor = BackgroundColor
body.appendChild(styleElem)
