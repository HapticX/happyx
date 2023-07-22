## # Card 🎴
## 
## Provides built-in Card component
## 
## > ⚠ Works only with `-d:enableUi` flag ⚠
## 
## .. image:: https://raw.githubusercontent.com/HapticX/happyx/master/screenshots/component_card.gif
## 
## 
## ### Params ⚙
## 
## | Name     | Type        | Required | Default Value      |
## | :---:    | :---:       | :---:    | :---:              |
## | `class`  | `string`    |  ❌      | `""`               |
## | `hAlign` | `Alignment` |  ❌      | `Alignment.aStart` |
## | `vAlign` | `Alignment` |  ❌      | `Alignment.aStart` |
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
  
  [methods]:
    proc setAlign*(vertical, horizontal: Alignment) =
      ## Changes Card alignment
      self.vAlignHidden =
        case vertical
        of aStart: remember "start"
        of aCenter: remember "center"
        else: remember "end"
      self.hAlignHidden =
        case horizontal
        of aStart: remember "start"
        of aCenter: remember "center"
        else: remember "end"
    
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
