## # Card 🎴
## 
## Provides built-in Card component
## 
## > ⚠ Works only with `-d:enableUi` flag ⚠
## 
## 
## ### Params ⚙
## 
## | Name    | Type     | Required | Default Value |
## | :---:   | :---:    | :---:    | :---:         |
## | `class` | `string` |  ❌      | `""`          |
## 
## Card has slot
## 


import
  ../../core/[constants, exceptions],
  ../renderer,
  ../state,
  ../components,
  ./palette,
  ./enums


type InputAction* = proc(str: cstring): void

const DefaultInputAction*: InputAction = proc(str: cstring) = discard


component Card:
  # action when any input
  *class: string = ""
  *hAlign: Alignment = Alignment.aStart
  *vAlign: Alignment = Alignment.aStart

  vAlignHidden: string = ""
  hAlignHidden: string = ""

  `template`:
    tDiv(class = self.class):
      slot
  
  `script`:
    self.vAlignHidden =
      if self.vAlign == aStart:
        remember "start"
      elif self.vAlign == aCenter:
        remember "center"
      else:
        remember "end"
    self.hAlignHidden =
      if self.hAlign == aStart:
        remember "start"
      elif self.hAlign == aCenter:
        remember "center"
      else:
        remember "end"
    
  `style`: """
    div {
      padding: 1rem 2rem;
      border-radius: .5rem;
      width: fit-content;
      display: flex;
      flex-direction: column;
      align-items: {self.hAlignHidden};
      justify-content: {self.vAlignHidden};
      color: {ForegroundColor};
      background: {BackgroundSecondaryColor};
    }
  """
