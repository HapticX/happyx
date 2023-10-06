<div align="center">

# HappyX
### for NodeJS

</div>


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
