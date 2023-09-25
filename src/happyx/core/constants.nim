## # Constants ✨
## > Provides HappyX constants
## 
## | Flag               | Description                                                | Need Value |
## | :---:              | :---:                                                      | :--:       |
## | `-d:httpx`         | enables Httpx as alternative HTTP Server ⚡                | ❌         |
## | `-d:beast`         | enables HttpBeast as alternative HTTP Server ⚡            | ❌         |
## | `-d:micro`         | enables MicroAsyncHttpServer as alternative HTTP Server ⚡ | ❌         |
## | `-d:translate`     | enables automatic translate for returns 🌐                  | ❌         |
## | `-d:debug`         | enables debug logging 💻                                   | ❌         |
## | `-d:oldRenderer`   | enables old renderer for SPA 🍍                            | ❌         |
## | `-d:enableUi`      | enables built-in UI components 🎴                          |  ❌        |
## | `-d:cryptoMethod`  | choose crypto method for `generate_password` methods 🔐    | ✅         |
## | `-d:numThreads`    | choose number of threads (httpx/httpbeast) ⌛              |  ✅        |
## | `-d:disableApiDoc` | disables built-in API documentation 📕                     | ❌         |
## | `-d:disableORM`    | disables built-in ORM 📑                                   | ❌         |
## | `-d:appName`       | choose name of application (SSR/SSG) 📕                    | ✅         |
## | `-d:apiDocsPath`   | choose path for API documentation 📕                       |  ✅        |
## 
## ## Dev Consts 👨‍💻
## 
## | Flag                      | Description                                                | Need Value |
## | :---:                     | :---:                                                      | :--:       |
## | `-d:compDebug`            | enables debug logging for components                       | ❌         |
## | `-d:ssrDebug`             | enables debug logging for SSR                              | ❌         |
## | `-d:spaDebug`             | enables debug logging for SPA                              | ❌         |
## | `-d:reqModelDebug`        | enables debug logging for request models                   | ❌         |
## | `-d:routingDebug`         | enables debug logging for routing                          | ❌         |
## | `-d:componentDebugTarget` | after this component program will terminated               | ✅         |
## | `-d:reqModelDebugTarget`  | after this request model program will terminated           | ✅         |
## 
import strformat
when not defined(js) and defined(debug):
  import terminal


# Configuration via `-d`/`--define`
const
  # Alternative HTTP Servers
  enableHttpx* = defined(httpx) or defined(happyxHttpx) or defined(hpxHttpx)
  enableMicro* = defined(micro) or defined(happyxMicro) or defined(hpxMicro)
  enableHttpBeast* = defined(beast) or defined(happyxBeast) or defined(hpxBeast)
  # Auto translation in routing
  enableAutoTranslate* = defined(translate) or defined(happyxTranslate) or defined(hpxTranslate)
  # Debug mode
  enableDebug* = defined(debug) or defined(happyxDebug) or defined(hpxDebug)
  enableDebugComponentMacro* = defined(compDebug) or defined(happyxCompDebug) or defined(hpxCompDebug)
  enableDebugSsrMacro* = defined(ssrDebug) or defined(happyxSsrDebug) or defined(hpxSsrDebug)
  enableDebugSpaMacro* = defined(spaDebug) or defined(happyxSpaDebug) or defined(hpxSpaDebug)
  enableUseCompDebugMacro* = defined(useCompDebug) or defined(happyxUseCompDebug) or defined(hpxUseCompDebug)
  enableRequestModelDebugMacro* = defined(reqModelDebug) or defined(happyxReqModelDebug) or defined(hpxReqModelDebug)
  enableRoutingDebugMacro* = defined(routingDebug) or defined(happyxRoutingDebug) or defined(hpxRoutingDebug)
  componentDebugTarget* {.strdefine.} = ""
  reqModelDebugTarget* {.strdefine.} = ""
  # Language bindings
  exportPython* = defined(export2py) or defined(happyxExport2py) or defined(hpxExport2py)
  # Framework features
  enableUi* = defined(enableUi) or defined(happyxEnableUi) or defined(hpxEnableUi)
  enableApiDoc* = not defined(disableApiDoc)
  enableOrm* = not defined(disableORM)
  numThreads* {. intdefine .} = 0
  appName* {.strdefine.} = "HappyX Application"
  apiDocsPath* {.strdefine.} = "/docs"
  cryptoMethod* {.strdefine.} = "sha512"
  httpMethods* = [
    "get", "post", "put", "patch", "link", "options", "head", "delete", "unlink", "purge", "copy"
  ]
  htmlTagsList* = [
    "a", "abbr", "address", "area", "article", "aside", "audio",
    "b", "base", "bdi", "bdo", "blockquote", "body", "br",
    "button", "canvas", "caption", "cite", "code", "col", "colgroup",
    "data", "datalist", "dd", "del", "details", "dfn", "dialog", "div",
    "dl", "dt", "em", "embed", "fieldset", "figcaption", "figure", "footer",
    "form", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header",
    "hgroup", "hr", "html", "i",
    "iframe", "img", "input", "ins", "kbd", "label", "legend", "li", "link",
    "main", "map", "mark", "menu", "meta", "meter", "nav", "noscript", "object",
    "ol", "optgroup", "option", "output", "p", "picture", "portal", "pre", "progress",
    "q", "rp", "rt", "ruby", "s", "samp", "script", "search", "section", "select",
    "slot", "small", "source", "span", "strong", "style", "sub", "summary", "sup",
    "svg", "cicle", "path", "g",
    "table", "tbody", "td", "template", "textarea", "tfoot", "th", "thead", "time",
    "title", "tr", "track", "u", "ul", "var", "video", "wbr",
  ]
  availableCryptoMethods = ["sha224", "sha256", "sha384", "sha512"]
  # Nim version
  nim_1_6_14* = (NimMajor, NimMajor, NimPatch) == (1, 6, 14)
  nim_2_0_0* = (NimMajor, NimMinor, NimPatch) >= (2, 0, 0)
  # Framework version
  HpxMajor* = 2
  HpxMinor* = 11
  HpxPatch* = 6
  HpxVersion* = $HpxMajor & "." & $HpxMinor & "." & $HpxPatch


when cryptoMethod notin availableCryptoMethods:
  raise newException(
    ValueError,
    fmt"cryptoMethod is wrong! it's can be {availableCryptoMethods}, but got {cryptoMethod}"
  )


when defined(js):
  const
    enableOldRenderer* = defined(oldRenderer) or defined(happyxOldRenrerer) or defined(hpxOldRenrerer)


when int(enableHttpx) + int(enableMicro) + int(enableHttpBeast) > 1:
  {. error: "You can't use two alternative servers at one time!" .}


when defined(debug):
  when not defined(js):
    styledEcho fgYellow, fmt"Enable auto translate:       {enableAutoTranslate}"
    styledEcho fgYellow, fmt"Enable httpbeast:            {enableHttpBeast}"
    styledEcho fgYellow, fmt"Enable httpx:                {enableHttpx}"
    styledEcho fgYellow, fmt"Enable MicroAsyncHttpServer: {enableMicro}"
  else:
    static:
      echo fmt"Enable auto translate:       {enableAutoTranslate}"
      echo fmt"Enable httpbeast:            {enableHttpBeast}"
      echo fmt"Enable httpx:                {enableHttpx}"
      echo fmt"Enable MicroAsyncHttpServer: {enableMicro}"
