# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


proc Reactivity*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"Reactivity ⚡"}
      
      tP: {translate"Let's open the topic of HappyX reactivity in more detail"}

      tP: {translate"To begin with, reactivity can be used both in components and outside of components."}

      tP: {translate"This example shows how to interact with reactive variables in the routes of the SPA application."}

      CodeBlock("nim", nimSpaReactivity1, "nim_spa_reactivity_1")

      tP:
        {translate"As you can see in the above code example, a special syntax is used to call the "}
        tCode: "inc()"
        {translate" function. This is necessary to simplify access to the value of the reactive variable."}
      
      tP: {translate"It is also worth noting that reactive variables are created using the remember function."}

      tP: {translate"The example below shows all the other examples of creating reactive variables."}

      CodeBlock("nim", nimSpaReactivity3, "nim_spa_reactivity_3")
      
      tP: {translate"Let's look at an example of working with sequences."}

      CodeBlock("nim", nimSpaReactivity2, "nim_spa_reactivity_2")

      tP:
        {translate"In the example above, the "}
        tCode: "len()"
        {translate" function is called without special syntax, since frequently used functions are implemented in reactive variables, such as "}
        
        tUl:
          tLi: tCode: "len"
          tLi: tCode: "$"
          tLi:
            tCode: "[]"
            tSpan: ", "
            tCode: "[]="
          tLi:
            tCode: "+="
            tSpan: ", "
            tCode: "-="
            tSpan: ", "
            tCode: "/="
            tSpan: ", "
            tCode: "*="
            tSpan: ", "
            tCode: "^="
            tSpan: ", "
            tCode: "~="
            tSpan: ", "
            tCode: "|="
            tSpan: ", "
            tCode: "&="
            tSpan: ", etc."
          tLi:
            tCode: "+"
            tSpan: ", "
            tCode: "-"
            tSpan: ", "
            tCode: "/"
            tSpan: ", "
            tCode: "*"
            tSpan: ", "
            tCode: "^"
            tSpan: ", "
            tCode: "~"
            tSpan: ", "
            tCode: "|"
            tSpan: ", "
            tCode: "&"
            tSpan: ", etc."
          tLi:
            tCode: ">"
            tSpan: ", "
            tCode: "<"
            tSpan: ", "
            tCode: "=="
            tSpan: ", "
            tCode: ">="
            tSpan: ", "
            tCode: "<="
            tSpan: ", "
            tCode: "!="
            tSpan: ", "
            tCode: "not"
      
      tP: {translate"Speaking of built-in frequently used functions, it is worth noting that they can be used together with ordinary values. Let's look at the following example."}

      CodeBlock("nim", nimSpaReactivity4, "nim_spa_reactivity_4")

      tP:
        {translate"To specify a new value for reactivity variables, you can use "}
        tCode: "set()"
        {translate". For example, you can use "}
        tCode: "set()"
        {translate" to replace the entire "}
        tCode: "seq[T]"
        {translate" in one go."}

      CodeBlock("nim", nimSpaReactivity5, "nim_spa_reactivity_5")
