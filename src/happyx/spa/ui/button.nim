## # Button Component ✨
## 
## Provides beautiful built-in button component
## 
## > ⚠ Works only with `-d:enableUi` flag ⚠
## 
## .. image:: https://raw.githubusercontent.com/HapticX/happyx/master/screenshots/component_button.gif
## 
## .. code-block:: nim
##    appRoutes "app":
##      "/":
##        component Button:
##          "Click me!"
##        tBr
##        component Button(flat = true):
##          "Click me!"
## 
## ### Params ⚙
## 
## | Name     | Type           | Required | Default Value            |
## | :---:    | :---:          | :---:    | :---:                    |
## | `action` | `proc(): void` | ❌       | `proc(): void = discard` |
## | `flat`   | `bool`         | ❌       | `false`                  |
## 
## Button has slot
## 

import
  ../../core/[constants, exceptions],
  ../renderer,
  ../state,
  ../components,
  ./palette,
  json


type ButtonAction* = proc(): void

const DefaultButtonAction*: ButtonAction = proc() = discard


component Button:
  # action when button is clicked
  *action: ButtonAction = DefaultButtonAction
  *flat: bool = false

  `template`:
    tButton(class = if self.flat: "flat" else: ""):
      slot
      @click:
        self.action()
  
  `style`: """
    button {
      display: flex;
      gap: .5rem;
      flex-direction: row;
      transition: all;
      transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
      transition-duration: .3s;
      border: 0;
      border-radius: .3rem;
      padding: .5rem 1rem;
      font-weight: 600;
      cursor: pointer;
      user-select: none;
      background: <AccentColor>;
    }

    button:hover {
      background: <AccentHoverColor>;
    }

    button:active {
      background: <AccentActiveColor>;
    }
    
    .flat {
      background: none;
      color: <AccentColor>;
    }

    .flat:hover {
      background: none;
      color: <AccentHoverColor>;
    }

    .flat:active {
      background: none;
      color: <AccentActiveColor>;
    }
  """
