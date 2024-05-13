# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[code, translations, steps],
  ../components/[
    button, guide_interactive, code_block
  ]


component Components:
  *counter: int = 0
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"Components 🔥"}
      tP: {translate"This article describes components and their behavior"}

      tH3: {translate"Button Example"}
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
      tP: {translate"The example above illustrates how HappyX handles clicks, and also demonstrates interaction with reactive data of the component."}

      tH3: {translate"Component properties"}
      tP: {translate"Components can have an unlimited number of props. These props can have default values."}

      CodeBlock("nim", nimSpaComponentsProps, "nim_props")

      tP: {translate"It is worth remembering that each property is automatically wrapped in State[]."}

      tH3: {translate"Component styles"}
      tP: {translate"Each component can have its own styles. They are isolated for each instance of the component."}
      
      CodeBlock("nim", nimSpaComponentsScopedStyle, "nim_style")

      tP: {translate"In this case, styles are applied only to the buttons inside the component. You may also notice that component property values can be inserted into styles."}
