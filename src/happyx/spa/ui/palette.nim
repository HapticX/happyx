## # Default UI Theme Palette 🎴
## 

when not defined(docgen):
  import dom

import json


const
  BackgroundColor* = "#0e090b"
  BackgroundSecondaryColor* = "#1e191b"
  BackgroundTerniaryColor* = "#2e292b"
  ForegroundColor* = "#ecedea"
  AccentColor* = "#fcff82"
  AccentHoverColor* = "#ecef72"
  AccentActiveColor* = "#dcdf62"
  SecondaryColor* = "#a8377b"
  SecondaryHoverColor* = "#98276b"
  SecondaryActiveColor* = "#88175b"


when not defined(docgen):
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
