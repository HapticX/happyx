# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[code, translations, steps],
  ../components/[
    button, guide_interactive, code_block
  ]


component Components:
  *counter: int = 0
  html:
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

      tH3: {translate"Component scripts"}
      tP: {translate"Each component can have its own script. This part of the code is executed directly before the component is rendered. Keep that in mind."}
      
      CodeBlock("nim", nimSpaComponentsScript, "nim_script")

      tH3: {translate"Component hooks"}
      tP:
        {translate"Components have a variety of different events. These include"}
        tUl:
          tLi:
            tCode: "@created"
            " - "
            {translate"Called once when the component is created."}
          tLi:
            tCode: "@updated"
            " - "
            {translate"Called when the HTML is fully updated."}
          tLi:
            tCode: "@rendered"
            " - "
            {translate"Called immediately after the component is rendered (before HTML update)."}
          tLi:
            tCode: "@beforeUpdated"
            " - "
            {translate"Called before the component is rendered."}
          tLi:
            tCode: "@exited"
            " - "
            {translate"Called during the window.beforeunload event."}
          tLi:
            tCode: "@pageShow"
            " - "
            {translate"Called during the window.pageshow event."}
          tLi:
            tCode: "@pageHide"
            " - "
            {translate"Called during the window.pagehide event."}

      tP: {translate"Here's how it all works together:"}
      tImg(src = "/happyx/public/component_lifecycle.jpg", class = "self-center rounded-xl")

      tH3: {translate"About slots in components"}
      tP:
        {translate"You can pass HTML into the component at any time. This is quite simple to do. You need to add a special instruction inside the HTML -"}
        " "
        tCode: "slot"
      tP: {translate"It looks like this:"}

      CodeBlock("nim", nimSpaComponentsSlot, "nim_comp_slot")
