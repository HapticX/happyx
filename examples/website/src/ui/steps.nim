import
  ../../../../src/happyx,
  ./translations


type
  Step* = object
    next*: int
    prev*: int
    title*, text*: string
    selections*: seq[tuple[start: int, finish: int]]


proc step*(title, text: string, selections: seq[tuple[start: int, finish: int]] = @[],
           prev: int = -1, next: int = -1): Step =
  Step(
    title: title, text: text, prev: prev, next: next, selections: selections
  )


var
  buttonSteps* = @[
    step(
      translate"Click",
      translate"Firstly, user clicks on the button",
    ),
    step(
      translate"Clicked",
      translate"@click event was detected",
      @[
        (116, 122),
      ],
      next = 2,
    ),
    step(
      translate"Counter up",
      translate"buttons'value (self.counter) increases by 1",
      @[
        (39, 55),
        (134, 149),
      ],
      prev = 1,
      next = 3
    ),
    step(
      translate"Re-rendering",
      translate"Current component detects that state was changed and re-renders only current component",
      @[
        (95, 107),
      ],
      prev = 2,
    )
  ]
