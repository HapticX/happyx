# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


proc Websockets*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: { translate"Websockets 🔌" }

      tP:
        { translate"Like other web frameworks, in HappyX you can use websockets. Below is an example of usage." }
      
      CodeBlock("nim", nimSsrWebsockets, "nim_ssr_websockets_ex")

      tP:
        { translate"In addition to the routes used above, websockets have other routes as well. Here is the complete list of all routes:" }
      CodeBlock("nim", nimSsrWebsocketsRoutes, "nim_ssr_websockets_routes")
