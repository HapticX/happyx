## # ProgressBar Component ✨
## 
## Provides beautiful built-in progress component
## 
## > ⚠ Works only with `-d:enableUi` flag ⚠
## 
## .. image:: https://raw.githubusercontent.com/HapticX/happyx/master/screenshots/component_progress.png
## 
## .. code-block:: nim
##    appRoutes "app":
##      "/":
##        component ProgressBar:
##          "Click me!"
##        tBr
##        component ProgressBar(ppCircle):
##          "Click me!"
## 
## ### Params ⚙
## 
## | Name           | Type                   | Required | Default Value                    |
## | :---:          | :---:                  | :---:    | :---:                            |
## | `action`       | `proc(val: int): void` | ❌       | `proc(val: int): void = discard` |
## | `progressType` | `ProgressBarType`      | ❌       | `ProgressBarType.ppHorizontal`   |
## | `showPercent`  | `bool`                 | ❌       | `false`                          |
## | `title`        | `string`               | ❌       | `""`                             |
## | `value`        | `string`               | ❌       | `0`                              |
## | `maxValue`     | `string`               | ❌       | `100`                            |
## | `size`         | `tuple[int, int]`      | ❌       | `(96, 24)`                       |
## 
## ProgressBar hasn't slot
## 

import
  ../../core/[constants, exceptions],
  ../renderer,
  ../state,
  ../components,
  ./palette,
  ./enums


type ProgressAction* = proc(val: int): void

const DefaultProgressAction*: ProgressAction = proc(val: int) = discard


component ProgressBar:
  # action when button is clicked
  *action: ProgressAction = DefaultProgressAction
  *progressType: ProgressBarType = ProgressBarType.ppHorizontal
  *showPercent: bool = true
  *title: string = ""
  *value: int = 0
  *maxValue: int = 100
  *size: tuple[a, b: int] = (96, 24)

  `template`:
    if self.progressType == ppHorizontal:
      tDiv(class = "container"):
        tDiv(class = "value-horizontal")
        tDiv(class = "placeholder"):
          if self.showPercent:
            "{self.title} {((self.value.toFloat / self.maxValue.toFloat) * 100.0).int}%"
          else:
            {self.title}
    elif self.progressType == ppVertical:
      tDiv(class = "container"):
        tDiv(class = "value-vertical")
        tDiv(class = "placeholder"):
          if self.showPercent:
            "{self.title} {((self.value.toFloat / self.maxValue.toFloat) * 100.0).int}%"
          else:
            {self.title}
    else:
      tDiv(class = "value-circle"):
        tDiv(class = "placeholder placeholder-circle"):
          if self.showPercent:
            "{self.title} {((self.value.toFloat / self.maxValue.toFloat) * 100.0).int}%"
          else:
            {self.title}
  
  `style`: """
    .container {
      display: flex;
      align-items: end;
      border-radius: .4rem;
      position: relative;
      transition: all .3s;
      width: {self.size.val[0]}px;
      height: {self.size.val[1]}px;
      background: {ForegroundColor};
    }
    .placeholder {
      position: absolute;
      top: 0;
      left: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      width: 100%;
      height: 100%; 
    }
    .placeholder-circle {
      position: static;
      color: {ForegroundColor};
    }

    .value-horizontal {
      border-radius: .4rem;
      transition: all .3s;
      height: 100%;
      background: {SecondaryColor};
      width: {((self.value.toFloat / self.maxValue.toFloat) * 100.0).int}%;
    }

    .value-vertical {
      border-radius: .4rem;
      transition: all .3s;
      width: 100%;
      background: {SecondaryColor};
      height: {((self.value.toFloat / self.maxValue.toFloat) * 100.0).int}%;
    }

    .value-circle {
      transition: all .3s;
      border-radius: 50%;
      background:
        radial-gradient(closest-side, {BackgroundColor} 79%, transparent 80% 100%),
        conic-gradient({SecondaryColor} {((self.value.toFloat / self.maxValue.toFloat) * 100.0).int}%, {ForegroundColor} 0);
      width: {self.size.val[0]}px;
      height: {self.size.val[1]}px;
    }

    .value-horizontal:hover {
      background: {SecondaryHoverColor};
    }
    .value-horizontal:active {
      background: {SecondaryActiveColor};
    }
    .value-vertical:hover {
      background: {SecondaryHoverColor};
    }
    .value-vertical:active {
      background: {SecondaryActiveColor};
    }
  """
