# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[code, translations, steps, colors],
  ../components/[
    button, code_block, tip
  ]


proc FlagsList*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: { translate"Compilation flags 🔨" }
      tP: { translate"This article discusses the compilation flags that you can use in HappyX." }

      tH2: { translate"Server flags ⚡" }
      tP: { translate"The main server flags are the flags for switching the server. HappyX supports 4 types of servers." }

      tTable(
        class = fmt"w-full rounded-md border-[1px] border-[{Foreground}] dark:border-[{ForegroundDark}]"
      ):
        tTr:
          tTd: { translate"Server" }
          tTd: { translate"Description" }
          tTd: { translate"Flag" }
        tTr:
          tTd: tA(href = "https://nim-lang.org/docs/asynchttpserver.html", target = "_blank"): tCode: "asynchttpserver"
          tTd: { translate"This server is part of the standard Nim library. It is used by default." }
          tTd: ""
        tTr:
          tTd: tA(href = "https://github.com/philip-wernersbach/microasynchttpserver", target = "_blank"): tCode: "microasynchttpserver"
          tTd: { translate"A reduced version of the default server." }
          tTd: tCode(class = "text-nowrap"): "-d:micro"
        tTr:
          tTd: tA(href = "https://github.com/dom96/httpbeast", target = "_blank"): tCode: "httpbeast"
          tTd: { translate"A fairly fast server that does not work on Windows." }
          tTd: tCode(class = "text-nowrap"): "-d:beast"
        tTr:
          tTd: tA(href = "https://github.com/ringabout/httpx", target = "_blank"): tCode: "httpx"
          tTd: { translate"Same as httpbeast, but works on Windows. Continually developed." }
          tTd: tCode(class = "text-nowrap"): "-d:httpx"
      
      tTable(
        class = fmt"w-full rounded-md border-[1px] border-[{Foreground}] dark:border-[{ForegroundDark}]"
      ):
        tTr:
          tTd: { translate"Flag" }
          tTd: { translate"Description" }
          tTd: { translate"Default value" }
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:disableApiDoc"
          tTd: { translate"Disables the generation of OpenAPI documentation (for swagger and redoc)" }
          tTd: ""
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:noliveviews"
          tTd: { translate"Disables all LiveViews functionality." }
          tTd: ""
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:safeRequests"
          tTd: { translate"Enables safe requests. On errors, a status code 500 and an error message will be returned." }
          tTd: ""

      # tH2: { translate"Client flags 🎴" }


      tH2: { translate"General purpose flags" }
      tP: { translate"These flags can be used in both server-side and client-side development." }
      
      tTable(
        class = fmt"w-full rounded-md border-[1px] border-[{Foreground}] dark:border-[{ForegroundDark}]"
      ):
        tTr:
          tTd: { translate"Flag" }
          tTd: { translate"Description" }
          tTd: { translate"Default value" }
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:disableDefDeco"
          tTd: { translate"Disables route decorators functionality." }
          tTd: ""
        # tTr:
        #   tTd: tCode: "-d:disableDefDeco"
        #   tTd: { translate"Disables route decorators functionality." }
        #   tTd: ""


      tH2: { translate"Debugging flags" }
      tP: { translate"These flags will help debug your program. They are also recommended to use if you plan to report any bugs in the GitHub repository." }
      
      tTable(
        class = fmt"w-full rounded-md border-[1px] border-[{Foreground}] dark:border-[{ForegroundDark}]"
      ):
        tTr:
          tTd: { translate"Flag" }
          tTd: { translate"Description" }
          tTd: { translate"Default value" }
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:debug"
          tTd: { translate"Enables debug logging." }
          tTd: ""
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:compDebug"
          tTd: { translate"Outputs information about components to the console during the program's compilation phase." }
          tTd: ""
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:ssrDebug"
          tTd: { translate"Outputs debug information about the server during the program's compilation phase." }
          tTd: ""
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:spaDebug"
          tTd: { translate"Outputs debug information about the single-page application during the program's compilation phase." }
          tTd: ""
        tTr:
          tTd: tCode(class = "text-nowrap"): "-d:reqModelDebug"
          tTd: { translate"Outputs debug information about the request models during the program's compilation phase." }
          tTd: ""
