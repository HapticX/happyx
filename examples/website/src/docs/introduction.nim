# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, translations],
  ../components/[code_block_guide, tip],
  jsffi


var localStorage {.importc, nodecl.}: JsObject


proc IntroductionLanguageChooser*(lang, title: string): TagRef =
  buildHtml:
    tDiv(
      class =
        if lang == currentLanguage:
          "text-center bg-yellow-400/20 dark:bg-yellow-300/25 px-4 py-2 select-none cursor-pointer rounded-md transition-all"
        else:
          "text-center bg-yellow-400/20 hover:bg-yellow-400/30 active:bg-yellow-400/40 dark:bg-yellow-200/10 px-4 py-2 select-none cursor-pointer rounded-md transition-all dark:hover:bg-yellow-200/20 dark:active:bg-yellow-300/10"
    ):
      {title}
      @click:
        var language: cstring = $lang
        localStorage["happyx_programming_language"] = language
        currentLanguage.set(lang)
        route(currentRoute)
        application.router()


proc Contributor*(nickname, url, avatar: string): TagRef =
  buildHtml:
    tA(class = "flex flex-col justify-center items-center", href = url):
      tImg(
        src = avatar,
        class = "w-[96px] lg:w-[72px] xl:w-[64px] h-[96px] lg:h-[72px] xl:h-[64px] rounded-full",
        alt = nickname,
        loading = "lazy",
        decoding = "async"
      )
      tP(class = "font-mono text-center h-8"):
        {nickname}


proc Badge*(name, src: string): TagRef = buildHtml:
  tImg(class = "h-12 lg:h-10 xl:h-8", alt = name, src = src, loading = "lazy", decoding = "async")


component Introduction:
  html:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tImg(
        src = "/happyx/public/icon.webp",
        alt = "happyx logo",
        class = "self-center w-72 h-72",
        loading = "lazy",
        decoding = "async"
      )
      tH1: {translate"Introduction ✌"}
      tTable:
        tTbody:
          tTr:
            tTd: "GitHub"
            tTd:
              tA(href = "https://github.com/HapticX/happyx"):
                Badge("Github Issues", "https://img.shields.io/github/issues/HapticX/happyx?style=for-the-badge")
              tA(href = "https://github.com/HapticX/happyx"):
                Badge("Github Closed Issues", "https://img.shields.io/github/issues-closed/HapticX/happyx?style=for-the-badge")
              tA(href = "https://github.com/HapticX/happyx"):
                Badge("Github Stars", "https://img.shields.io/github/stars/HapticX/happyx?style=for-the-badge")
          tTr:
            tTd: "Tests"
            tTd:
              tA(href = "https://github.com/HapticX/happyx/actions/workflows/tests.yml"):
                Badge("Github Issues", "https://img.shields.io/github/actions/workflow/status/HapticX/HappyX/tests.yml?label=Testing&logo=github&style=for-the-badge")
          tTr:
            tTd: "Languages"
            tTd:
              tA(href = "https://nim-lang.org"):
                Badge("Nim 👑", "https://img.shields.io/badge/>=1.6.14-1b1e2b?style=for-the-badge&logo=nim&logoColor=f1fa8c&label=Nim&labelColor=2b2e3b")
              tA(href = "https://python.org"):
                Badge("Python 🐍", "https://img.shields.io/badge/>=3.7.x-1b1e2b?style=for-the-badge&logo=python&logoColor=f1fa8c&label=Python&labelColor=2b2e3b")
              tA(href = "https://developer.mozilla.org/en-US/docs/Web/JavaScript"):
                Badge("JavaScript ✌", "https://img.shields.io/badge/ES6-1b1e2b?style=for-the-badge&logo=javascript&logoColor=f1fa8c&label=JavaScript&labelColor=2b2e3b")
              tA(href = "https://www.typescriptlang.org/"):
                Badge("TypeScript 🔥", "https://img.shields.io/badge/>=5.2.2-1b1e2b?style=for-the-badge&logo=typescript&logoColor=f1fa8c&label=TypeScript&labelColor=2b2e3b")
          tTr:
            tTd: "Wakatime Stats"
            tTd:
              tA(href = "https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1"):
                Badge("Wakatime", "https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1.svg?style=for-the-badge")
          tTr:
            tTd: "VS Code Plugin"
            tTd:
              tA(href = "https://github.com/HapticX/hpx-vs-code"):
                Badge("VS Code Plugin Repository", "https://img.shields.io/badge/Plugin-1b1e2b?style=for-the-badge&logo=visualstudiocode&logoColor=f1fa8c&label=VS%20Code&labelColor=2b2e3b")
              tA(href = "https://marketplace.visualstudio.com/items?itemName=HapticX.happyx"):
                Badge("Visual Studio Marketplace Installs - Azure DevOps Extension", "https://img.shields.io/visual-studio-marketplace/azure-devops/installs/total/HapticX.happyx?style=for-the-badge")
          tTr:
            tTd: "PyPI"
            tTd:
              tA(href = "https://pypi.org/project/happyx/"):
                Badge("PyPI Downloads", "https://img.shields.io/pypi/dm/happyx?style=for-the-badge")
          tTr:
            tTd: "npm"
            tTd:
              tA(href = "https://www.npmjs.com/package/happyx"):
                Badge("Npm Downloads", "https://img.shields.io/npm/dm/happyx?style=for-the-badge")
      tH2: {translate"What Is HappyX? 💡"}
      tP:
        tB: "HappyX"
        {translate"""
        is a macro-oriented full-stack web framework, written in Nim.
        This project has been under development since April 2023 and is continuously evolving.
        HappyX draws inspiration from notable web frameworks like Vue.js and FastAPI.
        """}
      Tip:
        tP:
          {translate"HappyX works with Nim, Python, JavaScript and TypeScript so you can choose one of these languages to read this guide ✌"}
        tDiv(
          class = "grid grid-cols-2 lg:grid-cols-4 w-fit gap-2 self-center"
        ):
          IntroductionLanguageChooser("Nim", "Nim 👑")
          IntroductionLanguageChooser("Python", "Python 🐍")
          IntroductionLanguageChooser("JavaScript", "JavaScript ✌")
          IntroductionLanguageChooser("TypeScript", "TypeScript 🔥")
      tP:
        tB: {translate"If you:"}
        tUl:
          tLi: {translate"""are not keen on constantly "switching" your mindset from one language or web framework to another 🔥"""}
          tLi: {translate"desire a lightweight web framework ⚡"}
          tLi: {translate"""seek a web framework with everything "out of the box" 📦"""}
        tB: {translate"Then, HappyX is the perfect fit for you. 😉"}
      tH2: {translate"Features 🔥"}
      tUl:
        tLi: {translate"Production-ready 🔌"}
        tLi: {translate"Multiple server options 🌩"}
        tLi: {translate"Support Single-page applications, Static site generation and Server-side rendering 💫"}
        tLi: {translate"Own Domain-specific languages for HTML, CSS and JavaScript 🎴"}
        tLi: {translate"Hot code reloading (only for Single-page applications for now) ⚡"}
        tLi: {translate"Routing/mounting with path param validation 👮‍♀️"}
        tLi: {translate"CLI for creating, serving and building your projects 💻"}
        tLi: {translate"Request models that supports JSON, FormData, x-www-form-urlencoded and XML 👮‍♀️"}
        tLi: {translate"""Translating, logging, security, built-in UI and more other features "out of the box" 📦"""}
      
      tDiv(class = "flex flex-col gap-8 pt-4"):
        tH2: {translate"Community 🌎"}
        tDiv(class = "flex flex-col gap-4"):
          tH3: {translate"Maintainers"}
          tDiv(class = "grid grid-cols-5 lg:grid-cols-10 xl:grid-cols-15 gap-x-2 gap-y-8"):
            Contributor("Ethosa", "https://github.com/Ethosa", "https://avatars.githubusercontent.com/u/49402667?v=4")
        tDiv(class = "flex flex-col gap-4"):
          tH3:
            {translate"Contributors"}
            " *"
          tDiv(class = "grid grid-cols-5 lg:grid-cols-10 xl:grid-cols-8 gap-x-2 gap-y-12"):
            Contributor("quimt", "https://github.com/quimt", "https://avatars.githubusercontent.com/u/126020181?v=4")
            Contributor("its5Q", "https://github.com/its5Q", "https://avatars.githubusercontent.com/u/12975646?v=4")
            Contributor("Lum", "https://github.com/not-lum", "https://avatars.githubusercontent.com/u/62594565?v=4")
            Contributor("Array in a Matrix", "https://github.com/array-in-a-matrix", "https://avatars.githubusercontent.com/u/78233840?v=4")
            Contributor("MCRusher", "https://github.com/MCRusher", "https://avatars.githubusercontent.com/u/16050377?v=4")
            Contributor("Sultan Al Isaiee", "https://github.com/foxoman", "https://avatars.githubusercontent.com/u/5356677?v=4")
            Contributor("Arik Rahman", "https://github.com/ArikRahman", "https://avatars.githubusercontent.com/u/40479733?v=4")
            Contributor("horanchikk", "https://github.com/horanchikk", "https://avatars.githubusercontent.com/u/46918417?v=4")
            Contributor("Stephan Zhdanov", "https://github.com/ret7020", "https://avatars.githubusercontent.com/u/55328925?v=4")
            Contributor("lost22git", "https://github.com/lost22git", "https://avatars.githubusercontent.com/u/65008815?v=4")
            Contributor("Optimax125", "https://github.com/Optimax125", "https://avatars.githubusercontent.com/u/53735809?v=4")
            Contributor("jbjuin", "https://github.com/jbjuin", "https://avatars.githubusercontent.com/u/2361571?v=4")
            Contributor("Matthew Stopa", "https://github.com/MattStopa", "https://avatars.githubusercontent.com/u/191057?v=4")
            Contributor("Carlo Capocasa", "https://github.com/capocasa", "https://avatars.githubusercontent.com/u/1167940?v=4")
            Contributor("Alikusnadi", "https://github.com/dodolboks", "https://avatars.githubusercontent.com/u/91905?v=4")
            Contributor("XADE", "https://github.com/imxade", "https://avatars.githubusercontent.com/u/56511165?v=4")
            Contributor("Thiago", "https://github.com/thisago", "https://avatars.githubusercontent.com/u/74574275?v=4")
            Contributor("svenrdz", "https://github.com/svenrdz", "https://avatars.githubusercontent.com/u/23420779?v=4")
            Contributor("monocoder", "https://github.com/monocoder", "https://avatars.githubusercontent.com/u/7921660?v=4")
            Contributor("JK", "https://github.com/jerrygzy", "https://avatars.githubusercontent.com/u/181757?v=4")
            Contributor("sjhaleprogrammer", "https://github.com/sjhaleprogrammer", "https://avatars.githubusercontent.com/u/60676867?v=4")
            Contributor("Constantine Molchanov", "https://github.com/moigagoo", "https://avatars.githubusercontent.com/u/1045340?v=4")
            Contributor("Derek", "https://github.com/derekdai", "https://avatars.githubusercontent.com/u/116649?v=4")
            Contributor("Александр Старочкин", "https://github.com/levovix0", "https://avatars.githubusercontent.com/u/53170138?v=4")
            Contributor("MouriKogorou", "https://github.com/MouriKogorou", "https://avatars.githubusercontent.com/u/43428806?v=4")
            Contributor("Devon", "https://github.com/winrid", "https://avatars.githubusercontent.com/u/1733933?v=4")
            Contributor("Yuriy Balyuk", "https://github.com/veksha", "https://avatars.githubusercontent.com/u/275333?v=4")
            Contributor("Damian Zaręba", "https://github.com/KhazAkar", "https://avatars.githubusercontent.com/u/12693890?v=4")
            Contributor("bluemax75", "https://github.com/bluemax75", "https://avatars.githubusercontent.com/u/11153375?v=4")
            Contributor("svbalogh", "https://github.com/svbalogh", "https://avatars.githubusercontent.com/u/46842029?v=4")
            Contributor("MelonCodeUK", "https://github.com/MelonCodeUK", "https://avatars.githubusercontent.com/u/138726110?v=4")
            Contributor("baseplate-admin", "https://github.com/baseplate-admin", "https://avatars.githubusercontent.com/u/61817579?v=4")
            Contributor("Yakumo-Yukari", "https://github.com/Yakumo-Yukari", "https://avatars.githubusercontent.com/u/12076232?v=4")
            Contributor("Daniel Obiorah", "https://github.com/Beetroit", "https://avatars.githubusercontent.com/u/87917539?v=4")
            Contributor("Basil Ajith", "https://github.com/bsljth", "https://avatars.githubusercontent.com/u/67640495?v=4")
            Contributor("AxelRHD", "https://github.com/AxelRHD", "https://avatars.githubusercontent.com/u/16512322?v=4")

          tP:
            { translate"And many other people, thanks to whom HappyX continues to develop to this day! ❤" }  
          
          tP(class = "text-base lg:text-sm xl:text-xs pt-4"):
            "* "
            { translate"This includes all members of the HappyX community who have contributed to its development (issues and pull requests)" }
