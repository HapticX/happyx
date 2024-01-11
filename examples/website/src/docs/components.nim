# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations, steps],
  ../components/[
    code_block_guide, code_block, code_block_slider, button,
    guide_interactive
  ]


component Components:
  *counter: int = 0
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"Components 🔥"}
      tP: {translate"This article describes components and their behavior"}

      tH2: {translate"Button Example"}
      tP: {translate"Let's look at Button component example"}
      
      GuideInteractive(
        buttonSteps,
        "nim",
        nimSpaComponentButton,
        "component_button",
      ):
        Button(
          action = proc() =
            self.counter += 1
            if scopeSelf.current_step == 0:
              scopeSelf.current_step.set(1)
              route(currentRoute)
              application.router()
        ):
          "counter {self.counter}"
