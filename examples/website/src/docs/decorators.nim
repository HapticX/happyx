# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider, tip
  ]


proc Decorators*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: { translate"Route Decorators 🔌" }

      tP: { translate"HappyX (at Nim side) provides efficient compile-time route decorators." }
      tP: { translate"Route decorators is little 'middleware', that edits route code at compile-time" }

      tH2: { translate"Usage 🤔" }
      tP: { translate"Here you can see simple decorator usage" }

      CodeBlock("nim", nimSsrRouteDecorator, "route_decorator")

      tH2: { translate"Decorators out of the box 📦" }
      tP: { translate"Basic Auth looks like this:" }
      
      CodeBlock("nim", nimAuthBasic, "auth_basic")

      tP: { translate"Authorization: JWT TOKEN and Authorization: Bearer JWT TOKEN look like this:" }
      
      CodeBlock("nim", nimAuthJWT, "auth_jwt")
      CodeBlock("nim", nimAuthBearerJWT, "auth_bearer_jwt")

      tP: { translate"You can also use the @Cached decorator to cache the result of your routes." }
      
      CodeBlock("nim", nimCachedDecorator, "cached_decorator")

      Tip:
        tDiv(class = "flex gap-2"):
          tP: { translate"To use JWT, you need to install the library" }
          tA(href = "https://github.com/yglukhov/nim-jwt", target = "_blank"):
            "yglukhov/nim-jwt"

      tH2: { translate"Custom Decorators 💡"}
      tP: { translate"You can create your own decorators also:" }

      CodeBlock("nim", nimAssignRouteDecorator, "route_decorator")

      Tip:
        tP: { translate"You can use route decorators in SSR, SSG, and SPA project types with Nim." }
