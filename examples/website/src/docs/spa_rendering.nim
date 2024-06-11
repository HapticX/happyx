# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


proc SpaRendering*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"SPA Rendering 🧩"}
      tP: {translate"This part of the documentation shows the rendering logic of single-page applications in HappyX"}

      tH2: {translate"Application rendering order"}
      tP:
        {translate"On the first visit to the site, after the JavaScript event"}
        " "
        tA(href = "https://developer.mozilla.org/en-US/docs/Web/API/Document/DOMContentLoaded_event", target = "_blank"):
          tCode:
            "DOMContentLoaded"
        " "
        {translate"a full rendering of the entire current page occurs."}
      tP:
        {translate"Further rendering occurs after comparing the virtual DOM with the real DOM."}
        " "
        {translate"If there is any deviation of the next new virtual DOM from the real one, the real DOM is changed."}
      tP:
        {translate"Such an algorithm is useful for frequent and precise changes on sites with a large amount of content."}
      
      tH2: {translate"Example"}
      tP:
        {translate"For clarity, let's look at the example below:"}
      
      CodeBlock("nim", nimSpaRendering, "nim_ssr_docs_1")

      tP:
        {translate"In the example above, on the first visit to the site, a variable is first declared"}
        " "
        tCode:
          "counter"
        {translate" then the initial rendering of the entire virtual DOM occurs (based on the page you are on)."}
      
