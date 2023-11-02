## # OpenAPI
## 
import
  ../spa/[tag, renderer],
  ../private/macro_utils,
  ../core/constants,
  ../sugar/sgr,
  ./server


let
  swaggerDocs* = buildHtml:
    tHtml:
      tHead:
        tTitle: "HappyX x Swagger"
        tMeta(charset = "utf-8")
        tLink(
          `type` = "text/css",
          rel = "stylesheet",
          href = "https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui.css"
        )
        tLink(rel = "shortcut icon")
      tBody:
        tDiv(id = "docs")
        tScript(src = "https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui-bundle.js")
        tScript: """
          const ui = SwaggerUIBundle({
            url: '/docs/openapi.json',
            oauth2RedirectUrl: window.location.origin + '/docs/swagger/oauth2-redirect',
            dom_id: '#docs',
            presets: [
              SwaggerUIBundle.presets.apis,
              SwaggerUIBundle.SwaggerUIStandalonePreset
            ],
            layout: "BaseLayout",
            deepLinking: true
          })
        """
  reDocs* = buildHtml:
    tHtml:
      tHead:
        tTitle: "HappyX x ReDoc"
        tMeta(charset = "utf-8")
        tLink(
          rel = "stylesheet",
          href = "https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700"
        )
        tStyle: """
          body {
            margin: 0;
            padding: 0;
          }
        """
      tBody:
        tRedoc("spec-url" = "/docs/openapi.json")
        tScript(src = "https://cdn.jsdelivr.net/npm/redoc@next/bundles/redoc.standalone.js")


"/docs/redoc" -> get:
  {.gcsafe.}:
    return reDocs


"/docs/swagger" -> get:
  {.gcsafe.}:
    return swaggerDocs
