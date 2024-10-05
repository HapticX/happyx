# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block
  ]


proc HpxProjectType*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: { translate"HPX project type 👀" }
      tP:
        { translate"This project type is suitable for you if you are familiar with any other JavaScript framework, such as Vue or Nuxt." }
      
      tH2: { translate"Creating a Project" }
      tP:
        { translate"To create an HPX project, you need to use the CLI:" }
      CodeBlock("shell", nimHpxCreateProjectExample, "hpx_create_example")
      tP:
        { translate"To run the project locally, use the command" }
      CodeBlock("shell", "hpx dev --reload", "hpx_dev_reload")

      tH2: { translate"Basic syntax" }
      tP:
        { translate"To begin, let's look at the basic syntax. Each component consists of three tags, each responsible for its own part." }
      
      tTable(
        class = fmt"w-full rounded-md border-[1px] border-[{Foreground}] dark:border-[{ForegroundDark}]"
      ):
        tTr:
          tTd: "Tag"
          tTd: { translate"Description" }
        tTr:
          tTd: tCode(class = "text-nowrap"): "<template></template>"
          tTd: { translate"This tag contains the HTML markup of the component. It also uses data from the script tag." }
        tTr:
          tTd: tCode(class = "text-nowrap"): "<script></script>"
          tTd: { translate"This tag contains Nim code. It is executed before the component is rendered." }
        tTr:
          tTd: tCode(class = "text-nowrap"): "<script lang=\"js\"></script>"
          tTd: { translate"In this tag, unlike regular script, the code is in JavaScript. However, data from here cannot be directly used in the HTML markup at this time." }
        tTr:
          tTd: tCode(class = "text-nowrap"): "<style></style>"
          tTd: { translate"In this tag, isolated CSS styles are stored." }
      
      tH3: "template"
      tP:
        { translate"When writing HTML code, you should not encounter any difficulties. Here, the main differences from regular HTML are also shown." } 
      CodeBlock("html", nimHpxTemplateExample, "hpx_template_example")
      
      tH3: "script"
      tP:
        { translate"If you are well-versed in Nim, you should not encounter any difficulties. Here, we declare a function and call it. We can also call a function in the template tag by wrapping it in curly braces." }
      CodeBlock("html", nimHpxScriptExample, "hpx_script_example")
      CodeBlock("html", nimHpxScriptExample_1, "hpx_script_example_1")
      
      tH3: "script js"
      tP:
        { translate"You can alternate this tag with a regular script tag." }
      CodeBlock("html", nimHpxScriptJsExample, "hpx_script_js_example")
      tP:
        { translate"It is worth noting that to use Nim from JS, functions and variables are usually marked with special types." }
      tP:
        { translate"In our case, we used the exportc pragma and specified the return type as cstring." }
      
      tH3: "style"
      tP:
        { translate"It's simple here - you just write CSS styles." }
      CodeBlock("html", nimHpxStyleExample, "hpx_script_js_example")
      tP:
        { translate"The styles of each component are isolated from each other." }
      
      tH2: { translate"Event handling 🧩" }
      tP:
        { translate"Event handling is tied to the use of HTML attributes." }
      CodeBlock("html", nimHpxEventsExample, "hpx_events_example")

      tP:
        { translate"You can view the complete list of events you can use in the MDN Docs." }
        tA(href = "https://developer.mozilla.org/en-US/docs/Web/Events", target = "_blank", class = "px-2"):
          { translate"More details" }
      
      tH2: { translate"Using Other Components within a Component" }
      tP:
        { translate"Just like in Vue, you can use components inside other components, thereby structuring your application." }
      
      tP: tCode: "components/HelloWorld.hpx"
      CodeBlock("html", nimHpxComponentsHelloWorldExample, "hpx_comphw_example")

      tP: tCode: "main.hpx"
      CodeBlock("html", nimHpxMainHpxExample, "hpx_mainhpx_example")

      tH2: { translate"Routing" }
      tP:
        { translate"You can declare routes using the router.json file. Let's consider an example of such a file below." }
      CodeBlock("json", nimHpxRouterExample, "hpx_mainhpx_example")
