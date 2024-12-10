## # Constants ✨
## > Provides HappyX constants
## 
## | Flag                 | Description                                                   | Need Value |
## | :---:                | :---:                                                         | :--:       |
## | `-d:httpx`           | enables Httpx as alternative HTTP Server ⚡                   | ❌         |
## | `-d:beast`           | enables HttpBeast as alternative HTTP Server ⚡               | ❌         |
## | `-d:micro`           | enables MicroAsyncHttpServer as alternative HTTP Server ⚡    | ❌         |
## | `-d:translate`       | enables automatic translate for returns 🌐                     | ❌         |
## | `-d:debug`           | enables debug logging 💻                                      | ❌         |
## | `-d:cryptoMethod`    | choose crypto method for `generate_password` methods 🔐       | ✅         |
## | `-d:numThreads`      | choose number of threads (httpx/httpbeast) ⌛                 |  ✅        |
## | `-d:sessionIdLength` | choose length of session ID ✍                                |  ✅        |
## | `-d:disableApiDoc`   | disables built-in API documentation 📕                        | ❌         |
## | `-d:appName`         | choose name of application (SSR/SSG) 📕                       | ✅         |
## | `-d:apiDocsPath`     | choose path for API documentation 📕                          |  ✅        |
## | `-d:noliveviews`     | Disables LiveViews at SSR/SSG (It helpful for components) 📕  |  ❌        |
## | `-d:safeRequests`    | Enables requests safety (On error returns 500 with err msg) 📕|  ❌        |
## | `-d:disableDefDeco`  | Disables default decorators (`AuthBasic`, `GetUserAgent`) 👀  |  ❌        |
## | `-d:disableComp`     | Disables default components. Only functional components will be enabled |❌|
## 
## ## Dev Consts 👨‍💻
## 
## | Flag                      | Description                                                | Need Value |
## | :---:                     | :---:                                                      | :--:       |
## | `-d:compDebug`            | enables debug logging for components                       | ❌         |
## | `-d:compTreeDebug`        | enables debug logging for components (tree mode)           | ❌         |
## | `-d:ssrDebug`             | enables debug logging for SSR                              | ❌         |
## | `-d:spaDebug`             | enables debug logging for SPA                              | ❌         |
## | `-d:reqModelDebug`        | enables debug logging for request models                   | ❌         |
## | `-d:routingDebug`         | enables debug logging for routing                          | ❌         |
## | `-d:componentDebugTarget` | after this component program will terminated               | ✅         |
## | `-d:reqModelDebugTarget`  | after this request model program will terminated           | ✅         |
## 


# Configuration via `-d`/`--define`
const
  # Alternative HTTP Servers
  enableMicro* = defined(micro) or defined(happyxMicro) or defined(hpxMicro)
  enableStd* = defined(stdserver) or defined(happyxStdserver) or defined(hpxStdserver)
  enableHttpx* = defined(httpx) or defined(happyxHttpx) or defined(hpxHttpx)
  enableHttpBeast* = defined(beast) or defined(happyxBeast) or defined(hpxBeast)
  enableBuiltin* = int(enableMicro) + int(enableStd) + int(enableHttpx) + int(enableHttpBeast) == 0
  # LiveViews
  enableLiveViews* = not (defined(noLiveviews) or defined(hpxNoLiveviews) or defined(happyxNoLiveviews))
  # Safe Requests
  enableSafeRequests* = defined(safeRequests) or defined(hpxSafeRequests) or defined(happyxSafeRequests)
  # Auto translation in routing
  enableAutoTranslate* = defined(translate) or defined(happyxTranslate) or defined(hpxTranslate)
  # Debug mode
  enableDebugComponentMacro* = defined(compDebug) or defined(happyxCompDebug) or defined(hpxCompDebug)
  enableDebugTreeComponentMacro* = defined(comp3Debug) or defined(happyxComp3Debug) or defined(hpxComp3Debug)
  enableDebugSsrMacro* = defined(ssrDebug) or defined(happyxSsrDebug) or defined(hpxSsrDebug)
  enableDebugSpaMacro* = defined(spaDebug) or defined(happyxSpaDebug) or defined(hpxSpaDebug)
  enableUseCompDebugMacro* = defined(useCompDebug) or defined(happyxUseCompDebug) or defined(hpxUseCompDebug)
  enableRequestModelDebugMacro* = defined(reqModelDebug) or defined(happyxReqModelDebug) or defined(hpxReqModelDebug)
  enableRoutingDebugMacro* = defined(routingDebug) or defined(happyxRoutingDebug) or defined(hpxRoutingDebug)
  enableDefaultDecorators* = not (defined(disableDefDeco) or defined(happyxDsableDefDeco) or defined(hpxDisableDefDeco))
  enableDefaultComponents* = not (defined(disableComp) or defined(happyxDisableComp) or defined(hpxDisableComp))
  enableAppRouting* = not (defined(disableRouting) or defined(happyxDisableRouting) or defined(hpxDisableRouting))
  enableTemplateEngine* = not (defined(disableTemplateEngine) or defined(happyxTemplateEngine) or defined(hpxTemplateEngine))
  componentDebugTarget* {.strdefine.} = ""
  reqModelDebugTarget* {.strdefine.} = ""
  # Language bindings
  exportPython* = defined(export2py) or defined(happyxExport2py) or defined(hpxExport2py)
  exportJvm* = defined(export2jvm) or defined(happyxExport2jvm) or defined(hpxExport2jvm)
  # Framework features
  enableHistoryApi* = defined(historyApi) or defined(hpxHistoryApi) or defined(happyxHistoryApi)
  enableDebug* = defined(debug) or defined(happyxDebug) or defined(hpxDebug) or exportJvm or exportPython or defined(napibuild)
  enableApiDoc* = not defined(disableApiDoc)
  enableColors* = not defined(disableColors) or not defined(happyxDisableColors) or not defined(hpxDisableColors)
  numThreads* {. intdefine .} = 0
  sessionIdLength* {.intdefine.} = 32
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
    "title", "tr", "track", "text", "u", "ul", "var", "video", "wbr",
  ]
  htmlNonBoolAttrs* = [
    "class", "id", "color", "border", "bgcolor", "charset", "accept", "accept-charset",
    "action", "allow", "accesskey", "http-equip", "kind", "lang", "language", "itemprop",
    "list", "type", "minlength", "maxlength", "placeholder", "role", "rows", "cols", "score",
    "src", "srcdoc", "srclang", "href", "ref", "summary", "step", "title", "translate",
    "width", "height", "wrap", "target", "srcset"
  ]
  availableCryptoMethods = ["sha224", "sha256", "sha384", "sha512"]
  # Nim version
  nim_1_6_14* = (NimMajor, NimMajor, NimPatch) == (1, 6, 14)
  nim_2_0_0* = (NimMajor, NimMinor, NimPatch) >= (2, 0, 0)
  # Framework version
  HpxMajor* = 4
  HpxMinor* = 6
  HpxPatch* = 5
  HpxVersion* = $HpxMajor & "." & $HpxMinor & "." & $HpxPatch


when cryptoMethod notin availableCryptoMethods or (enableDebug and not defined(js)):
  import strformat
when not defined(js) and enableDebug and enableColors:
  import terminal


when cryptoMethod notin availableCryptoMethods:
  raise newException(
    ValueError,
    fmt"cryptoMethod is wrong! it's can be {availableCryptoMethods}, but got {cryptoMethod}"
  )


when defined(js):
  const
    enableOldRenderer* = defined(oldRenderer) or defined(happyxOldRenrerer) or defined(hpxOldRenrerer)


when int(enableHttpx) + int(enableMicro) + int(enableHttpBeast) > 1:
  {. error: "You can't use two or more alternative servers at one time!" .}


when enableDebug:
  when not defined(js) and enableColors:
    styledEcho fgYellow, fmt"Enable auto translate:       {enableAutoTranslate}"
    styledEcho fgYellow, fmt"Enable httpbeast:            {enableHttpBeast}"
    styledEcho fgYellow, fmt"Enable httpx:                {enableHttpx}"
    styledEcho fgYellow, fmt"Enable MicroAsyncHttpServer: {enableMicro}"
  elif not enableColors:
    echo fmt"Enable auto translate:       {enableAutoTranslate}"
    echo fmt"Enable httpbeast:            {enableHttpBeast}"
    echo fmt"Enable httpx:                {enableHttpx}"
    echo fmt"Enable MicroAsyncHttpServer: {enableMicro}"
