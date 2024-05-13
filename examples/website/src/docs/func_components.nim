# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[code, translations, steps],
  ../components/[
    button, code_block, tip
  ]


proc FuncComponents*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"Functional components 🧪"}
      tP: {translate"This part explains functional components and how they work."}

      tH3: {translate"Difference from regular components"}

      tP: {translate"Unlike regular components, functional components do not support inheritance, properties, methods, and other features of regular components."}
      tP: {translate"Based on their name, functional components are functions that return VDOM."}

      tP: {translate"Here's an example of a simple functional component:"}

      CodeBlock("nim", nimSpaFuncComp1, "func_comp_1")

      tP: {translate"As you can see, functional components always return the TagRef type. This is the VDOM."}
      tP: {translate"You are free to handle the outgoing VDOM as you wish, not necessarily adhering to the template above."}

      tH3: {translate"Slots in functional components"}
      tP:
        {translate"In addition, functional components, like regular ones, support slots. To use a slot, you need to define the last argument of the function like this:"}
        " "
        tCode: "stmt: TagRef = nil"
      Tip(TipType.ttWarning):
        tP: {translate"It is important that the argument is named exactly like this and nothing else! Default value can be omitted."}

      tP: {translate"Here's an example of a component using a slot:"}

      CodeBlock("nim", nimSpaFuncComp2, "func_comp_2")
