## # API Doc Template 📕
## 
import
  strformat,
  ../core/constants


const
  Back = "#ceeffe"
  BackDark = "#212121"
  BackCode = "#becfee"
  BackCodeDark = "#323232"
  Fore = "#212121"
  ForeDark = "#ceeffe"
  Link = "text-[#5e7fae] visited:text-[#3e5f8e] dark:text-[#ceeffe] dark:visited:text-[#8badcf]"

  AccentColor = "text-purple-700 dark:text-yellow-500"
  StringColor = "text-lime-700 dark:text-green-500"


const IndexApiDocPageTemplate* = fmt"""
<html>
  <head>
    <meta charset="utf-8">
    <meta property="og:title" content="{{{{title}}}}">
    <title>{{{{title}}}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/nim.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/json.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/http.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/tokyo-night-dark.min.css">
    <script>
      var converter = converter = new showdown.Converter();
      var descriptionElement = null;
      var descriptionText = null;

      converter.setOption('strikethrough', true);
      converter.setOption('tables', true);
      converter.setOption('ghCodeBlocks', true);
      converter.setOption('tasklists', true);
      converter.setOption('openLinksInNewWindow', true);
      converter.setOption('emoji', true);
      converter.setOption('underline', true);
    </script>
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Comfortaa&display=swap');
      :root {{  
        font-family: Comfortaa;
      }}
      @media (prefers-color-scheme: dark) {{
        ::-webkit-scrollbar {{
          width: 12px;
        }}
        ::-webkit-scrollbar-track {{
          background: {BackCode}25;
        }}
        ::-webkit-scrollbar-thumb {{
          background-color: {BackCode}25;
          border-radius: 20px;
          border: 3px solid {BackCode}25;
        }}
      }}
      @media (prefers-color-scheme: light) {{
        ::-webkit-scrollbar {{
          width: 12px;
        }}
        ::-webkit-scrollbar-track {{
          background: {BackCodeDark}25;
        }}
        ::-webkit-scrollbar-thumb {{
          background-color: {BackCodeDark}25;
          border-radius: 20px;
          border: 3px solid {BackCodeDark}25;
        }}
      }}
    </style>
  </head>
  <body class="bg-[{Back}] dark:bg-[{BackDark}] text-[{Fore}] dark:text-[{ForeDark}]">
    <div class="flex flex-col w-full min-h-screen h-full">
      <div class="flex sticky top-0 justify-center items-center backdrop-blur-md text-5xl lg:text3xl xl:text-2xl font-semibold py-4">
        {{{{title}}}}
      </div>
      <!-- http method -->
      {{% proc apiDoc(httpMethod: string): string = %}}
        {{%
          let data = collect:
            for req in apiDocData:
              if req.httpMethod == httpMethod or (httpMethod.len == 0 and req.httpMethod.len == 0):
                req
        %}}
        {{% if data.len > 0 %}}
          <div class="text-3xl lg:text-lg xl:text-base flex flex-col w-full opacity-100 h-fit">
            <div class="text-4xl lg:text-xl xl:text-lg flex self-center w-full justify-between">
              <p>
                HTTP Method - <span class="font-semibold font-mono {AccentColor} cursor-pointer select-none">
                  {{% if httpMethod.len == 0 %}}
                    ANY
                  {{% else %}}
                    {{{{ httpMethod }}}}
                  {{% endif %}}
                </span>
              </p>
              <svg
                id="httpMethod_{{{{httpMethod}}}}_arrow"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
                class="cursor-pointer select-none w-16 lg:w-12 xl:w-8 h-16 lg:h-12 xl:h-8 fill-[{Fore}] dark:fill-[{ForeDark}] rotate-0 transition-all duration-300"
                onclick="toggle('httpMethod_{{{{httpMethod}}}}', 'httpMethod_{{{{httpMethod}}}}_arrow')"
              >
                <path
                  d="M5.70711 9.71069C5.31658 10.1012 5.31658 10.7344 5.70711 11.1249L10.5993 16.0123C11.3805 16.7927 12.6463 16.7924 13.4271 16.0117L18.3174 11.1213C18.708 10.7308 18.708 10.0976 18.3174 9.70708C17.9269 9.31655 17.2937 9.31655 16.9032 9.70708L12.7176 13.8927C12.3271 14.2833 11.6939 14.2832 11.3034 13.8927L7.12132 9.71069C6.7308 9.32016 6.09763 9.32016 5.70711 9.71069Z"
                />
              </svg>
            </div>
            <div id="httpMethod_{{{{httpMethod}}}}" class="flex flex-col gap-6 lg:gap-4 xl:gap-2 h-fit transition-all duration-300">
            {{% for req in data %}}
              <div class="flex flex-col w-fit border-[2px] border-[{Fore}]/25 dark:border-[{ForeDark}]/25 rounded-md">
                <div class="flex p-1 bg-[{BackCode}] dark:bg-[{BackCodeDark}] font-mono px-4 py-1 rounded-md font-semibold">
                  <p class="flex mr-4 {AccentColor} cursor-pointer select-none">
                    {{% if req.httpMethod.len == 0 %}}
                      ANY  <!-- HTTP Method -->
                    {{% else %}}
                      {{{{ req.httpMethod }}}}  <!-- HTTP Method -->
                    {{% endif %}}
                  </p>
                  <p class="flex">
                    <span class="pr-2">at</span>
                    <span class="{StringColor}">
                    &quot;{{{{ req.path }}}}&quot;
                    </span>  <!-- PATH -->
                  </p>
                </div>
                <div id="{{{{httpMethod}}}}_{{{{req.path}}}}_desc" class="flex flex-col w-fit px-2 py-1">
                  {{{{ req.description }}}}  <!-- Description -->
                </div>
                {{% if req.pathParams.len > 0 %}}
                  <div class="font-semibold py-1 px-2">Path params</div>
                  <div class="p-2">
                    <table class="rounded-md text-3xl lg:text-xl xl:text-base">
                      <thead>
                        <tr>
                          <td class="px-2">Name</td>
                          <td class="px-2">Type</td>
                          <td class="px-2">Default Value</td>
                          <td class="px-2">Optional</td>
                          <td class="px-2">Mutable</td>
                        </tr>
                      </thead>
                      <tbody>
                        {{% for (idx, param) in req.pathParams.pairs() %}}
                          {{%
                            let color =
                              if idx mod 2 == 0:
                                "bg-[{Fore}]/20 dark:bg-[{ForeDark}]/20"
                              else:
                                "bg-[{Fore}]/10 dark:bg-[{ForeDark}]/10"
                          %}}
                          <tr class="{{{{color}}}} py-1">
                            <td class="px-2">{{{{param.name}}}}</td>
                            <td class="px-2 {AccentColor} font-mono">{{{{param.paramType}}}}</td>
                            <td class="px-2 {AccentColor} font-mono">{{{{param.defaultVal}}}}</td>
                            <td class="text-center align-middle px-2">
                              {{% if param.optional %}}✅{{% else %}}❌{{% endif %}}
                            </td> 
                            <td class="text-center align-middle px-2">
                              {{% if param.mutable %}}✅{{% else %}}❌{{% endif %}}
                            </td>
                          </tr>
                        {{% endfor %}}
                      </tbody>
                    </table>
                  </div>
                {{% endif %}}
                {{% if req.models.len > 0 %}}
                  <div class="font-semibold py-1 px-2">Request models</div>
                  <div class="p-2">
                    <table class="rounded-md text-3xl lg:text-xl xl:text-base">
                      <thead>
                        <tr>
                          <td class="px-2">Name</td>
                          <td class="px-2">Type</td>
                          <td class="px-2">Target</td>
                          <td class="px-2">Mutable</td>
                        </tr>
                      </thead>
                      <tbody>
                        {{% for (idx, model) in req.models.pairs() %}}
                          {{%
                            let color =
                              if idx mod 2 == 0:
                                "bg-[{Fore}]/20 dark:bg-[{ForeDark}]/20"
                              else:
                                "bg-[{Fore}]/10 dark:bg-[{ForeDark}]/10"
                          %}}
                          <tr class="{{{{color}}}} py-1">
                            <td class="px-2">{{{{model.name}}}}</td>
                            <td class="px-2 {AccentColor} font-mono">{{{{model.typeName}}}}</td>
                            <td class="px-2 {AccentColor} font-mono">{{{{model.target}}}}</td>
                            <td class="text-center align-middle px-2">
                              {{% if model.mutable %}}✅{{% else %}}❌{{% endif %}}
                            </td>
                          </tr>
                        {{% endfor %}}
                      </tbody>
                    </table>
                  </div>
                {{% endif %}}
              </div>
              <script>
                {{%
                  var descText = req.description.replace("`", "\\`")
                %}}
                descriptionText = converter.makeHtml(`{{{{descText}}}}`);
                descriptionElement = document.getElementById("{{{{httpMethod}}}}_{{{{req.path}}}}_desc");
                descriptionElement.innerHTML = descriptionText;
              </script>
            {{% endfor %}}
            </div>
          </div>
        {{% else %}}
        {{% endif %}}
      {{% endproc %}}

      <div class="flex flex-col w-full lg:w-fit gap-16 lg:gap-12 xl:gap-6 items-center self-center h-full p-8 lg:p-0">
        {{{{ apiDoc("") }}}}
        {{{{ apiDoc("GET") }}}}
        {{{{ apiDoc("POST") }}}}
        {{{{ apiDoc("PUT") }}}}
        {{{{ apiDoc("DELETE") }}}}
        {{{{ apiDoc("HEAD") }}}}
        {{{{ apiDoc("LINK") }}}}
        {{{{ apiDoc("UNLINK") }}}}
        {{{{ apiDoc("PURGE") }}}}
        {{{{ apiDoc("OPTIONS") }}}}
        {{{{ apiDoc("CONNECT") }}}}
        {{{{ apiDoc("TRACE") }}}}
        <div class="w-48 h-48 py-12">&nbsp;</div>
      </div>

      <div class="text-3xl lg:text-xl xl:text-base fixed bottom-0 flex flex-col justify-center items-center w-full bg-[{BackCode}] dark:bg-[{BackCodeDark}] py-8">
        <p>
          Made with 
          <a href="https://github.com/HapticX/happyx" class="{Link}">
            HappyX
          </a> v{hpxVersion}
        </p>
      </div>
    </div>
    <script>
      let toggled = {{}};
      function toggle(identifier, arrow) {{
        let section = document.getElementById(identifier);
        let arw = document.getElementById(arrow);

        if (identifier in toggled) {{
          toggled[identifier] = !toggled[identifier];
          if (toggled[identifier]) {{
            // show
            arw.classList.remove("rotate-90");
            arw.classList.add("rotate-0");
            section.classList.remove("h-0");
            section.classList.remove("opacity-0");
            section.classList.add("h-fit");
            section.classList.add("opacity-100");
          }} else {{
            // hide
            arw.classList.remove("rotate-0");
            arw.classList.add("rotate-90");
            section.classList.remove("h-fit");
            section.classList.remove("opacity-100");
            section.classList.add("h-0");
            section.classList.add("opacity-0");
          }}
        }} else {{
          toggled[identifier] = true;
          // hide
          arw.classList.remove("rotate-0");
          arw.classList.add("rotate-90");
          section.classList.remove("h-fit");
          section.classList.remove("opacity-100");
          section.classList.add("h-0");
          section.classList.add("opacity-0");
        }}
      }}
      hljs.highlightAll();
    </script>
  </body>
</html>
"""
