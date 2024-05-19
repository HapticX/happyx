# Import HappyX
import
  sequtils,
  random,
  regex,
  ../../../../src/happyx,
  ../path_params,
  ../components/[header, smart_card, card, button, section, code_block, about_section, drawer],
  ../ui/[colors, translations]


randomize()
const sessionIdChars = concat(toSeq('a'..'z'), toSeq('A'..'Z'), toSeq('0'..'9'))

proc genSessionId*: string =
  result = "hpxs_"
  for i in 0..32:
    result &= sessionIdChars[rand(sessionIdChars.len-1)]


var
  drawer_comp* = use:
    component Drawer
  sandboxSessionId*: cstring = cstring genSessionId()
  sandboxCode*: cstring = ""
  sharedCode*: bool = false
  compiled*: bool = false


{.emit: """//js
var monacoEditor = null;
""".}
when defined(production):
  {.emit:"const sandboxApiBase = 'https://hapticx.ru/';".}
elif defined(docker):
  {.emit:"const sandboxApiBase = 'http://' + window.location.host + '/';".}
else:
  {.emit:"const sandboxApiBase = 'http://127.0.0.1:5123/';".}

var websiteBase* =
  when defined(production):
    "https://hapticx.github.io/happyx/"
  elif defined(docker):
    "http://" & $window.location.host & "/"
  else:
    "http://127.0.0.1:5000/"


proc writeLine*(text: cstring) {.exportc.} =
  {.emit: """//js
  document.getElementById("sandbox_terminal_output").innerHTML += "\n" + `text`;
  document.getElementById("sandbox_terminal_container").scroll({
    top: sandbox_terminal_output.offsetHeight ,
    left: 0,
    behavior: "smooth",
  });
  """.}


proc reload*() {.exportc.} =
  {.emit: """//js
  let sandbox_terminal = document.getElementById("sandbox_terminal");
  // output
  writeLine('Reloading ...');
  // reload
  let sandbox_frame = document.getElementById("sandbox_frame");
  sandbox_frame.contentWindow.location.hash = '#/start';
  sandbox_frame.contentDocument.head.innerHTML = '<meta charset="utf-8">';
  // output
  writeLine('<span class="text-green-400">Success</span>');
  """.}


proc compile*() {.exportc.} =
  compiled = true
  {.emit: """//js
  let sandbox_frame = document.getElementById("sandbox_frame");
  let sandbox_terminal = document.getElementById("sandbox_terminal");
  let sandbox_terminal_container = document.getElementById("sandbox_terminal_container");
  let waitUntilInterval = null;
  writeLine("Compiling ...");
  function waitUntil() {
    fetch(sandboxApiBase + "task/" + `sandboxSessionId` + "/completed").then(response => {
      response.json().then(json => {
        if (typeof json["response"] === 'object') {
          clearInterval(waitUntilInterval);
          // div id="root"
          let appDiv = document.createElement("div");
          appDiv.id = "root";
          // script src="nim js"
          let scriptElem = document.createElement("script");
          let js = json["response"]["js"];
          // add new function
          js = js.replace(/console\.log/g, 'hpx_log');
          js = 'function hpx_log(...data){console.log(...data);window.parent.writeLine(data.toString())}\n' + js;
          scriptElem.innerHTML = js;
          // add children
          let output = json['response']['output'];
          output = output.replace(/\[([^\]]+)\]/g, '<span class="text-blue-400">[$1]</span>');
          output = output.replace(/Warning:/g, '<span class="text-yellow-400">Warning:</span>');
          output = output.replace(/Hint:/g, '<span class="text-green-400">Hint:</span>');
          output = output.replace(/Error:/g, '<span class="text-red-400">Error:</span>');
          output = output.replace(/Exception:/g, '<span class="text-red-400">Exception:</span>');
          output = output.replace(
            /main\.(js|nim)\((\d+) *, *(\d+)\)/g,
            '<span onclick="moveCursorTo($2, $3)" class="duration-150 cursor-pointer underline hover:text-blue-200 active:text-blue-300">main.$1($2, $3)</span>'
          );
          writeLine("");
          writeLine(output);
          sandbox_terminal_container.scroll({
            top: sandbox_terminal_output.offsetHeight ,
            left: 0,
            behavior: "smooth",
          });
          sandbox_frame.contentDocument.body.innerHTML = "";
          sandbox_frame.contentDocument.head.innerHTML = '<meta charset="utf-8">';
          sandbox_frame.contentDocument.body.appendChild(appDiv);
          sandbox_frame.contentDocument.body.appendChild(scriptElem);
        }
      })
    });
  }
  sandbox_frame.contentWindow.location.reload();
  fetch(sandboxApiBase,
    {
      method: "POST",
      body: JSON.stringify({
        "code": `sandboxCode`,
        "id": `sandboxSessionId`
      }),
    }
  ).then(response => {
    response.json().then(json => {
      if (json['response'] !== 'error') {
        waitUntilInterval = setInterval(waitUntil, 250);
      } else {
        writeLine('<span class="text-red-400">Exception[' + json['error_code'] + ']:</span>');
        writeLine('<span class="text-red-400">  ' + json['error'] + '</span>');
      }
    })
  });
  """.}


proc codeId*() {.exportc.} =
  if compiled:
    writeLine(fmt"This code available at <span class='text-purple-400'>{sandboxSessionId}</span>")
  else:
    writeLine(fmt"<span class='text-yellow-400'>Code ID will available after compilation</span>")


proc codeLink*() {.exportc.} =
  if compiled:
    writeLine(
      "This code available at <a href='" &
      websiteBase & "#/sandbox/" & $sandboxSessionId &
      "' class='underline duration-150 text-purple-200 hover:text-purple-300 active:text-purple-400'>" &
      websiteBase & "#/sandbox/"  & $sandboxSessionId & "</a>"
    )
  else:
    writeLine(fmt"<span class='text-yellow-400'>Code link will available after compilation</span>")


proc changeMonacoTheme*(theme: cstring) {.exportc.} =
  echo theme
  case $theme
  of "vs", "vs-dark", "nim-theme", "hc-black", "hc-light":
    {.emit:"""//js
    monacoEditor.updateOptions({"theme": `theme`});
    """.}
    writeLine("<span class='text-green-400'>Successfully updated theme</span>")
  of "help", "":
    writeLine("<span class='text-yellow-400'>theme theme-name")
    writeLine("  changes curent theme to one of available:")
    writeLine("  - vs;")
    writeLine("  - vs-dark;")
    writeLine("  - hc-black;")
    writeLine("  - hc-light;")
    writeLine("  - nim-theme</span>")
  else:
    writeLine("<span class='text-red-400'>unknown theme</span>")


proc updateSandboxId*() {.exportc.} =
  sandboxSessionId = cstring genSessionId()
  compiled = false
  sharedCode = false


proc handleCommand*(command: cstring) {.exportc.} =
  writeLine(fmt"<span class='text-purple-400'>$&gt;</span> {command}")
  case $command
  of "rerun", "run", "compile":
    compile()
  of "reload", "restart":
    reload()
  of "code-id", "get-code-id":
    codeId()
  of "link", "get-link":
    codeLink()
  of "help":
    writeLine("<span class='text-yellow-400'>HappyX sandbox terminal v1.1.0")
    writeLine("  You can use it to manage sandbox")
    writeLine("")
    writeLine("  Commands:")
    writeLine("  - compile (aliases is `run` and `rerun`)")
    writeLine("    Compiles current code")
    writeLine("  - reload (alias is `restart`)")
    writeLine("    Restarts current program")
    writeLine("  - get-code-id (alias is `code-id`)")
    writeLine("    Outputs share code")
    writeLine("  - get-link (alias is `link`)")
    writeLine("    Outputs share code link")
    writeLine("  - theme")
    writeLine("    Changes editor theme")
    writeLine("  - help")
    writeLine("    Shows this message</span>")
  else:
    if ($command).startsWith("theme"):
      changeMonacoTheme(cstring ($command)[5..^1].strip())
    else:
      writeLine("<span class='text-red-400'>unknown command</span>")
  document.getElementById("sandbox_terminal_snippet").innerHTML = ""


proc sendToTerminal*() {.exportc.} =
  {.emit: """//js
  let sandbox_terminal_input = document.getElementById("sandbox_terminal_input");
  handleCommand(sandbox_terminal_input.value);
  sandbox_terminal_input.value = "";
  """.}


proc addCommand*(commandName: cstring) {.exportc.} =
  {.emit: """//js
  let sandbox_terminal_input = document.getElementById("sandbox_terminal_input");
  handleCommand(`commandName`);
  sandbox_terminal_input.value = "";
  """.}


proc moveCursorTo*(line, symbol: int) {.exportc.} =
  {.emit: """//js
  monacoEditor.setSelection({
    startColumn: `symbol`,
    endColumn: `symbol`,
    startLineNumber: `line`,
    endLineNumber: `line`,
  });
  document.querySelector('.monaco').focus();
  """.}


component SandBoxEditor:
  `template`:
    tDiv(id = nu"editor_container", class = "flex w-full xl:w-1/2 flex-col"):
      tDiv(
        class = "monaco w-full h-[64rem] xl:h-[36rem] bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"
      )
  
  @updated:
    {.emit: """//js
    if (monacoEditor === null) {
      monacoEditor = monaco.editor.create(
        document.querySelector('.monaco'), {
          value: 'import happyx\n\n' +
                '# Tailwind CSS 3 auto included\n' +
                '# declare application with id "root" (please, don\'t change)\n' +
                'appRoutes "root":\n' +
                '  # main route, should be "/start".\n' +
                '  "/start":\n' +
                '    tDiv(class = "flex flex-col gap-2 p-2"):\n' +
                '      "Hello, world!"\n' +
                '      tButton(class = "w-fit rounded-md px-4 bg-red-400 hover:bg-red-500"):\n' +
                '        "go to /visit"\n' +
                '        # on click event\n' +
                '        @click:\n' +
                '          # go to the other route\n' +
                '          route("/visit")\n' +
                '  "/visit":\n' +
                '    "Hello!"\n',
          theme: "nim-theme",
          language: "nim",
          minimap: { enabled: true },
          automaticLayout: true,
          smoothScrolling: true,
          fontSize: isPhone() ? 28 : 14,
        }
      );
      if (`sharedCode`) {
        fetch(sandboxApiBase + "task/" + `sandboxSessionId` + "/code").then(response => {
          response.json().then(json => {
            if (typeof json['response'] === 'string'){
              `sandboxCode` = json['response'];
              monacoEditor.setValue(json['response']);
              updateSandboxId();
              writeLine("<span class='text-green-400'>shared code from " + `sandboxSessionId` + "</span>");
            } else {
              `sandboxCode` = monacoEditor.getValue();
            }
          });
        });
      } else {
        `sandboxCode` = monacoEditor.getValue();
      }
      monacoEditor.onDidChangeModelContent(function(event) {
        `sandboxCode` = monacoEditor.getValue();
      });
      let sandbox_frame = document.getElementById("sandbox_frame");
      sandbox_frame.contentDocument.body.innerHTML = "";
      sandbox_frame.contentDocument.head.innerHTML = '<meta charset="utf-8">';
      let sandbox_terminal_input = document.getElementById("sandbox_terminal_input");
      sandbox_terminal_input.onkeypress = function(e){
        if (!e) e = window.event;
        var keyCode = e.code || e.key;
        if (keyCode == 'Enter'){
          // Enter pressed
          handleCommand(sandbox_terminal_input.value);
          sandbox_terminal_input.value = "";
          return false;
        }
      }
      function changePlaceholder() {
        if (sandbox_terminal_input.placeholder === '')
          sandbox_terminal_input.placeholder = '|';
        else
          sandbox_terminal_input.placeholder = '';
      }
      setInterval(changePlaceholder, 500);
    }
    """.}


mount SandBox:
  "/{sId?:string[m]}":
    nim:
      {.emit: "monacoEditor = null;".}
      sandboxSessionId = genSessionId()
      sharedCode = false
      compiled = false
      if sId.len > 0:
        sandboxSessionId = cstring sId
        sharedCode = true
        compiled = true
    tDiv(class = "flex flex-col min-h-screen w-full bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      # Drawer
      drawer_comp
      # Header
      tDiv(class = "w-full sticky top-0 z-20"):
        Header(drawer = drawer_comp)
      tDiv(class = "flex xl:hidden justify-evenly text-2xl lg:text-lg xl:text-base py-4"):
        tButton(
          id = "editor_button",
          class = "py-2 px-2 border-b-[1px] border-transparent opacity-[.6] hover:opacity-[.8] active:opacity-100 duration-150"
        ):
          "EDITOR"
          @click:
            let
              editorButton = document.getElementById("editor_button")
              viewButton = document.getElementById("view_button")
              editorContainer = document.getElementById("editor_container")
              viewContainer = document.getElementById("view_container")
            editorButton.classList.add(fmt"border-[{Foreground}]")
            editorButton.classList.add(fmt"dark:border-[{ForegroundDark}]")
            editorButton.classList.remove("border-transparent")
            viewButton.classList.remove(fmt"border-[{Foreground}]")
            viewButton.classList.remove(fmt"dark:border-[{ForegroundDark}]")
            viewButton.classList.add("border-transparent")
            viewContainer.classList.add("scale-0")
            viewContainer.classList.remove("scale-100")
        tButton(
          id = "view_button",
          class = "py-2 px-2 border-b-[1px] border-transparent hover:border-[{Foreground}] dark:hover:border-[{ForegroundDark}] opacity-[.6] hover:opacity-[.8] active:opacity-100 duration-150"
        ):
          "VIEW"
          @click:
            let
              editorButton = document.getElementById("editor_button")
              viewButton = document.getElementById("view_button")
              editorContainer = document.getElementById("editor_container")
              viewContainer = document.getElementById("view_container")
            editorButton.classList.add(fmt"border-[{Foreground}]")
            editorButton.classList.add(fmt"dark:border-[{ForegroundDark}]")
            editorButton.classList.remove("border-transparent")
            viewButton.classList.remove(fmt"border-[{Foreground}]")
            viewButton.classList.remove(fmt"dark:border-[{ForegroundDark}]")
            viewButton.classList.add("border-transparent")
            viewContainer.classList.add("scale-100")
            viewContainer.classList.remove("scale-0")
      tDiv(class = "flex w-full h-full overflow-hidden justify-center items-center"):
        SandBoxEditor
        tDiv(
          id = "view_container",
          class = "duration-150 absolute z-50 scale-0 xl:scale-100 xl:z-0 xl:static w-full h-[64rem] xl:h-[36rem] bg-white"
        ):
          tIframe(
            id = "sandbox_frame",
            src = fmt"{websiteBase}#/start",
            name = "result",
            class = "w-full h-full",
            sandbox = "allow-scripts allow-modals allow-same-origin allow-presentation allow-top-navigation allow-top-navigation-by-user-activation",
            allow = "*"
          )
      tDiv(
        id = "sandbox_terminal",
        class = "w-full h-full p-2 max-h-[48rem] min-h-[48rem] xl:min-h-[16rem] xl:max-h-[16rem] bg-[{BackgroundDark}] "
      ):
        tDiv(class = "flex gap-4 py-4 xl:py-0 text-2xl lg:text-lg xl:text-base"):
          tButton(class = "py-2 px-2 border-b-[1px] border-transparent hover:border-[{Foreground}] dark:hover:border-[{ForegroundDark}] opacity-[.6] hover:opacity-[.8] active:opacity-100 duration-150"):
            "COMPILE"
            @click:
              compile()
          tButton(class = "py-2 px-2 border-b-[1px] border-transparent hover:border-[{Foreground}] dark:hover:border-[{ForegroundDark}] opacity-[.6] hover:opacity-[.8] active:opacity-100 duration-150"):
            "RESTART CURRENT"
            @click:
              reload()
          tButton(class = "xl:hidden py-2 px-2 border-b-[1px] border-transparent hover:border-[{Foreground}] dark:hover:border-[{ForegroundDark}] opacity-[.6] hover:opacity-[.8] active:opacity-100 duration-150"):
            "SEND TO TERMINAL"
            @click:
              sendToTerminal()
          tButton(class = "py-2 px-2 border-b-[1px] border-transparent hover:border-[{Foreground}] dark:hover:border-[{ForegroundDark}] opacity-[.6] hover:opacity-[.8] active:opacity-100 duration-150"):
            "SHARE CODE"
            @click:
              codeLink()
        tDiv(
          id = "sandbox_terminal_snippet",
          class = "text-3xl lg:text-xl xl:text-base absolute z-50 empty:opacity-0 empty:scale-0 empty:-translate-y-1/2 duration-150 transition-all backdrop-shadow-2xl rounded-md overflow-hidden -translate-y-full w-fit h-fit bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}]"
        )
        tDiv(
          id = "sandbox_terminal_container",
          class = "overflow-auto w-full max-h-[47rem] xl:max-h-[17rem] flex flex-col"
        ):
          tPre(id = "sandbox_terminal_output", class = "text-3xl lg:text-xl xl:text-base px-2 pt-1"):
            "HappyX Sandbox v1.1.0"
          tInput(
            placeholder = "|",
            id = "sandbox_terminal_input",
            class = "text-3xl lg:text-xl xl:text-base peer w-full bg-transparent outline-none px-2 text-[{Foreground}] dark:text-[{ForegroundDark}]",
          ):
            @focusin(event):
              {.emit: """//js
              let sandbox_terminal_snippet = document.getElementById('sandbox_terminal_snippet');
              sandbox_terminal_snippet.classList.add('scale-100');
              sandbox_terminal_snippet.classList.add('opacity-100');
              sandbox_terminal_snippet.classList.remove('scale-0');
              sandbox_terminal_snippet.classList.remove('opacity-0');
              """.}
            @input(event):
              var cmd = event.target.InputElement.value;
              {.emit: """//js
              let sandbox_terminal_snippet = document.getElementById('sandbox_terminal_snippet');
              let sandbox_terminal_input = document.getElementById("sandbox_terminal_input");
              let command = `cmd`;
              let elem = document.createElement('div');
              elem.setAttribute('class', 'group flex px-6 py-3 xl:py-1 cursor-pointer bg-white/[.05] opacity-[.6] hover:opacity-[.8] active:opacity-100 duration-150');
              sandbox_terminal_snippet.innerHTML = "";

              let x = window.scrollX + sandbox_terminal_input.getBoundingClientRect().left;
              let y = window.scrollY + sandbox_terminal_input.getBoundingClientRect().top;

              const commands = {
                'link': 'get share code link',
                'get-link': 'get share code link',
                'rerun': 'compiles current code',
                'run': 'compiles current code',
                'compile': 'compiles current code',
                'reload': 'go to the "/start" route',
                'restart': 'go to the "/start" route',
                'code-id': 'get code ID',
                'get-code-id': 'get code ID',
                'help': 'shows help message',
                'theme vs': 'changes editor theme to vs',
                'theme vs-dark': 'changes editor theme to vs-dark',
                'theme hc-light': 'changes editor theme to hc-light',
                'theme hc-black': 'changes editor theme to hc-dark',
                'theme nim-theme': 'changes editor theme to nim-theme',
              }
              for (const [key, value] of Object.entries(commands)) {
                if (command === '')
                  continue;
                if (command.includes(key) || key.includes(command)) {
                  let div = elem.cloneNode(true);
                  div.innerHTML = '<div class="w-64">' + key + '</div><div class="truncate duration-150 transition-all w-32 group-hover:w-fit max-w-[24rem]">' + value + '</div>';
                  // div.addEventListener('click', e => addCommand(key));
                  div.setAttribute('onclick', "addCommand('" + key + "')")
                  sandbox_terminal_snippet.appendChild(div);  
                }
              }
              sandbox_terminal_snippet.style.left = x + 'px';
              sandbox_terminal_snippet.style.top = (y - 5) + 'px';
              """.}
        tStyle: """
          @import url('https://fonts.googleapis.com/css2?family=Fira+Code&display=swap');

          #sandbox_terminal_output, #sandbox_terminal_input, #sandbox_terminal_snippet {
            font-family: 'Fira Code', monospace;
          }
          #sandbox_terminal_input:focus::placeholder {
            color: transparent;
          }
        """
