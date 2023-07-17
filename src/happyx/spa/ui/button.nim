## # Button Component ✨
## 
## Provides beautiful built-in button component
## 
## > ⚠ Works only with `-d:enableUi` flag ⚠
## 
## ### Params ⚙
## 
## | Name     | Type           | Required | Default Value            |
## | :---:    | :---:          | :---:    | :---:                    |
## | `action` | `proc(): void` | ❌       | `proc(): void = discard` |
## 
## Button has slot
## 

import
  ../../core/[constants, exceptions],
  ../renderer,
  ../state,
  ../components,
  ./palette


type ButtonAction* = proc(): void

const DefaultButtonAction*: ButtonAction = proc() = discard


component Button:
  # action when button is clicked
  *action: ButtonAction = DefaultButtonAction

  `template`:
    tButton:
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
      background: {AccentColor};
    }

    button:hover {
      background: {AccentHoverColor};
    }

    button:active {
      background: {AccentActiveColor};
    }
  """
