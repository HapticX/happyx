<div align="center">

![Happyx](https://user-images.githubusercontent.com/49402667/228402522-6dd72d4b-c21c-4acf-b1e2-8318b6e809da.png)
### Macro-oriented asynchronous full-stack web-framework written in Nim with ♥

![Nim language](https://img.shields.io/badge/>=1.6.12-1b1e2b?style=for-the-badge&logo=nim&logoColor=f1fa8c&label=Nim&labelColor=2b2e3b)
[![wakatime](https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1.svg?style=for-the-badge)](https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1)
[![Testing](https://img.shields.io/github/actions/workflow/status/HapticX/HappyX/tests.yml?label=Testing&logo=github&style=for-the-badge)](https://github.com/HapticX/happyx/actions/workflows/tests.yml)

</div>


# Why HappyX? 💁‍♀️
> HappyX is a web framework with asynchronous, macro-oriented, full stack support.

In HappyX you can write `single page`, `static site generation` and `server side rendering` applications 💡

You can write Rest API with HappyX also 🔌

HappyX is very simple to use. Keep your peace of mind 🙂

## Why Not Jester/Karax? 🤔
Jester and Karax have many features, but Jester is a `backend web framework`, and Karax is a `frontend web framework`. HappyX  is a `full-stack web framework` that combines the features of Jester and Karax and slightly improves them 🛠

With HappyX you mustn't learn new libraries/frameworks to switch between `frontend` and `backend`. You can switch between them easily using HappyX ✌

HappyX is macro-oriented web framework so you mustn't write a lot of code ✨

## Features ⚡
- Multiple options for HTTP server! Happyx use `asynchttpserver` as default HTTP server (`httpx` via `-d:httpx` and `microhttpserver` via `-d:micro` as alternative HTTP servers).
- Support `SPA` on `JS` backend and `SSG` on other backends.
- Build HTML, CSS and pure JS with `buildHtml`, `buildStyle` and `buildJs` macros.
- Request JSON models with `model` macro.
- Routing and powerful path params.
- Assignment path params with `pathParams` macro.
- Powerful mounting sub-applications with `mount` macro. 
- Logging with `-d:debug`.
- CLI tool for `creating`, `serving` and `building` your projects.
- Hot code reloading (only for `SPA` projects as of now).

## Minimal Example 👩‍💻

<table height="180px">
  <thead>
    <tr>
      <td align="center">SPA</td>
      <td align="center">SSG</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <pre lang="nim"><code>
import happyx

    appRoutes("app"):
      "/":
        "Hello, world!"
</code></pre>
      </td><td>
      <pre lang="nim"><code>
      import happyx
    
      
    serve("127.0.0.1", 5000):
      "/":
        "Hello, world!"
</code></pre>
      </td>
    <tr>
  </tbody>
</table>

# Get Started 👨‍🔬

## Installing 📥

|        Nimble   |  GitHub    |
|        :---     |  :---      |
| <pre lang="bash">nimble install happyx</pre> | <pre lang="bash">nimble install https://github.com/HapticX/happyx</pre> |

## Usage ▶
### SSG
```bash
hpx create --name ssg_project --kind SSG
cd ssg_project/src
```

Main script will be able in `/ssg_project/src/main.nim`

#### Run 💻

|           Default        |             Httpx                 |       microasynchttpserver        |
|           :---           |             :---                  |             :---                  |
| <pre lang="bash">nim c -r -d:debug main</pre> | <pre lang="bash">nim c -r -d:debug -d:httpx main</pre> | <pre lang="bash">nim c -r -d:debug -d:micro main</pre> |

### SPA
```bash
hpx create --name spa_project --kind SPA --path-params
cd spa_project
```

Main script will be able in `/spa_project/src/main.nim`

#### Run 💻
Just run this command and see magic ✨
```bash
hpx dev --reload
```


# Have A Nice Idea? 🍍

[Open issue](https://github.com/HapticX/happyx/issues/new/choose) or contact us hapticx.company@gmail.com


# Contributing 🌀
See [Contributing.md](https://github.com/HapticX/happyx/blob/master/.github/CONTRIBUTING.md) for more information


## Star History ✨

[![Star History Chart](https://api.star-history.com/svg?repos=HapticX/happyx&type=Date)](https://star-history.com/#HapticX/happyx&Date)
