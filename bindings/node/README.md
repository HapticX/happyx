<div align="center">

# HappyX
### for NodeJS

</div>


*Currently bindings works only on Linux. To use it on Windows - use [WSL](https://learn.microsoft.com/windows/wsl/install)*


## Getting Started

### Install
```shell
npm install happyx
```


## Examples

### ECHO Server

```typescript
import { Server, Request } from "happyx";

const app = new Server();

app.get("/", (req: Request) => {
    return "Hello, world!";
});

app.start();
```
