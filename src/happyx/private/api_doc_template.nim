## # API Doc Template 📕
## 
import
  strformat


const
  Back = "#ceeffe"
  BackDark = "#212121"
  BackCode = "#becfee"
  BackCodeDark = "#323232"
  Fore = "#212121"
  ForeDark = "#ceeffe"


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
    </style>
  </head>
  <body>
    <div class="flex flex-col w-screen min-h-screen bg-[{Back}] dark:bg-[{BackDark}] text-[{Fore}] dark:text-[{ForeDark}]">
      <p class="flex justify-center items-center text-4xl lg:text3xl xl:text-2xl font-semibold py-4">
        {{{{title}}}}
      </p>
      <!-- http method -->
      {{% proc apiDoc(httpMethod: string): string = %}}
        {{%
          let data = collect:
            for req in apiDocData:
              if req[0] == httpMethod or (httpMethod.len == 0 and req[0].len == 0):
                req
        %}}
        {{% if data.len > 0 %}}
          <div class="flex flex-col w-full">
            <div class="self-center">
              HTTP Method - <span class="font-semibold font-mono text-purple-500 cursor-pointer select-none">
                {{% if httpMethod.len == 0 %}}
                  ANY
                {{% else %}}
                  {{{{ httpMethod }}}}
                {{% endif %}}
              </span>
            </div>
            <div id="httpMethod_{{{{httpMethod}}}}" class="flex flex-col gap-2">
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
                    <span class="text-green-500">"{{{{ req[2] }}}}"</span>  <!-- PATH -->
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

      <div class="flex flex-col w-fit gap-6 items-center self-center ">
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
    </div>
  </body>
</html>
"""
