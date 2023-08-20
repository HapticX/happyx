<div align="center">

# HappyX

### Python Bindings For HappyX Web Framework 🔥

![Python language](https://img.shields.io/badge/>=3.10.x-1b1e2b?style=for-the-badge&logo=python&logoColor=f1fa8c&label=Python&labelColor=2b2e3b)

</div>


## Get Started

### Install

You can install HappyX via `pypi`:
```bash
pip install happyx
```

## Usage

### Hello World

```py
from happyx import new_server


app = new_server('127.0.0.1', 5000)  # host and port are optional params


@app.get('/')
def home():
    return "Hello world!"


app.start()
```


### JSON/HTML/File Responses

```py
from happyx import new_server, JsonResponse, HtmlResponse, FileResponse


app = new_server()


@app.get('/json')
def json_resp():
    return JsonResponse(
      {'key': 'value', 'arr': [1, 2, 3, 4, 5]},
      status_code=200  # also available headers: dict param
    )


@app.get('/html')
def html_resp():
    return HtmlResponse(
      '<h1>HTML Response!</h1>',
      status_code=200  # also available headers: dict param
    )


@app.get('/file')
def file_resp():
    return FileResponse('my_cool_icon.png')


app.start()
```

Read more in [User Guide](https://hapticx.github.io/happyx/#/guide/)
