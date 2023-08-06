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
  ForeLink = "#abcdff"
  ForeLinkVisited = "#8badcf"


const IndexApiDocPageTemplate* = fmt"""
<html>
  <head>
    <meta charset="utf-8">
    <title>{{{{title}}}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
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
      <div class="flex sticky justify-center items-center text-4xl lg:text3xl xl:text-2xl font-semibold py-4">
        {{{{title}}}}
      </div>
      <!-- http method -->
      {{% proc apiDoc(httpMethod: string): string = %}}
        {{%
          let data = collect:
            for req in apiDocData:
              if req[0] == httpMethod or (httpMethod.len == 0 and req[0].len == 0):
                req
        %}}
        {{% if data.len > 0 %}}
          <div class="flex flex-col w-full opacity-100 h-fit">
            <div class="flex self-center w-full justify-between">
              <p>
                HTTP Method - <span class="font-semibold font-mono text-purple-500 cursor-pointer select-none">
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
                class="cursor-pointer select-none w-8 h-8 fill-[{Fore}] dark:fill-[{ForeDark}] rotate-0 transition-all duration-300"
                onclick="toggle('httpMethod_{{{{httpMethod}}}}', 'httpMethod_{{{{httpMethod}}}}_arrow')"
              >
                <path
                  d="M5.70711 9.71069C5.31658 10.1012 5.31658 10.7344 5.70711 11.1249L10.5993 16.0123C11.3805 16.7927 12.6463 16.7924 13.4271 16.0117L18.3174 11.1213C18.708 10.7308 18.708 10.0976 18.3174 9.70708C17.9269 9.31655 17.2937 9.31655 16.9032 9.70708L12.7176 13.8927C12.3271 14.2833 11.6939 14.2832 11.3034 13.8927L7.12132 9.71069C6.7308 9.32016 6.09763 9.32016 5.70711 9.71069Z"
                />
              </svg>
            </div>
            <div id="httpMethod_{{{{httpMethod}}}}" class="flex flex-col gap-2 h-fit transition-all duration-300">
            {{% for req in data %}}
              <div class="flex flex-col w-fit border-[2px] border-[{Fore}]/25 dark:border-[{ForeDark}]/25 rounded-md">
                <div class="flex p-1 bg-[{BackCode}] dark:bg-[{BackCodeDark}] font-mono px-4 py-1 rounded-md font-semibold">
                  <p class="flex mr-4 text-purple-500 cursor-pointer select-none">
                    {{% if req[0].len == 0 %}}
                      ANY  <!-- HTTP Method -->
                    {{% else %}}
                      {{{{ req[0] }}}}  <!-- HTTP Method -->
                    {{% endif %}}
                  </p>
                  <p class="flex">
                    <span class="pr-2">at</span>
                    <span class="text-green-500">
                    &quot;{{{{ req[2] }}}}&quot;
                    </span>  <!-- PATH -->
                  </p>
                </div>
                <p class="flex w-fit px-2 py-1">
                  {{{{ req[1] }}}}  <!-- Description -->
                </p>
              </div>
            {{% endfor %}}
            </div>
          </div>
        {{% else %}}
        {{% endif %}}
      {{% endproc %}}

      <div class="flex flex-col w-fit gap-6 items-center self-center h-full">
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
      </div>

      <div class="flex flex-col justify-center items-center w-full bg-[{BackCode}] dark:bg-[{BackCodeDark}] py-8 mt-8">
        <p>
          Made with 
          <a href="https://github.com/HapticX/happyx" class="text-[{ForeLink}] visited:text-[{ForeLinkVisited}]">
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
    </script>
  </body>
</html>
"""
