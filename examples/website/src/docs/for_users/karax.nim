# Import HappyX
import
  ../../../../../src/happyx,
  ../../ui/[colors, code, play_states, translations],
  ../../components/[
    code_block_guide, code_block, code_block_slider, tip
  ]


proc KaraxUsers*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"HappyX for Karax users 👑"}

      tP: {translate"This article discusses the differences between Karax and HappyX, as well as their pros and cons."}

      tH2: "Hello, world!"

      tP: {translate"I propose to consider the first example from the Karax README:"}

      CodeBlock("nim", karaxHelloWorld, "nim_vs_karax_karax_ex1")

      tP: {translate"Here's how you can rewrite it using HappyX:"}

      CodeBlock("nim", happyxVsKaraxHelloWorld1, "nim_vs_karax_happyx_ex1")

      tP:
        {translate"However, if you look again, you can see that the Karax example uses a function that returns VDOM."}
        " "
        {translate"In HappyX, you can also use functions to generate VDOM:"}

      CodeBlock("nim", happyxVsKaraxHelloWorld2, "nim_vs_karax_happyx_ex2")

      tH2: {translate"The event model"}

      tP:
        {translate"Now let's consider the event model provided by HappyX and Karax."}

      CodeBlock("nim", karaxEventModel, "nim_vs_karax_karax_ex2")
      CodeBlock("nim", happyxVsKaraxEventModel, "nim_vs_karax_happyx_ex3")

      tP:
        {translate"Unlike Karax, HappyX does not change the event model and allows you to embed as many events as you like on a single element."}
        " "
        {translate"You are also free to change the variable name responsible for the event:"}
      CodeBlock("nim", happyxVsKaraxEventModel1, "nim_vs_karax_happyx_ex4")
      
