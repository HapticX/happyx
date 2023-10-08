import { AssertionError } from 'assert';
import { TCore, IWebSocket, IRequest } from './TNode';
const hpx: TCore = require('./bin/node.node'); // .node is "C" instance

export enum WSState {
    CONNECT = "wssConnect",
    OPEN = "wssOpen",
    CLOSE = "wssClose",
    HANDSHAKE_ERROR = "wssHandshakeError",
    MISMATCH_PROTOCOL = "wssMismatchProtocol",
    ERROR = "wssError"
}

/**
 * Creates an instance of a WebSocketClient.
 * @param {IWebSocket} ws - The WebSocket object representing the connection.
*/
export class WebSocketClient {
    private id: string;
    public data: string;
    public path: string;
    public state: WSState;

    constructor(ws: IWebSocket) {
        this.id = ws.websocketId;
        this.data = ws.data;
        this.path = ws.path;
        this.state = WSState.CONNECT;
        this.setState(ws.state);
    }

    /**
     * Changes current WebSocket state
     * @param {string} state WebSocket state from happyx bindings
     * 
     * @throws {TypeError} when state is not websocket state.
     */
    public setState(state: string) {
        for (const key of Object.keys(WSState) as (keyof typeof WSState)[]) {
            if (WSState[key] === state) {
                this.state = WSState[key];
                return;
            }
        }
        throw new TypeError(`${state} is not WebSocket state!`);
    }

    /**
     * Sends a text message over the WebSocket connection.
     * @param {string} text - The text message to send.
     */
    public sendText(text: string) {
        hpx.hpxWebSocketSendText(this.id, text);
    }

    /**
     *  Sends a JSON object over the WebSocket connection.
     * @param {object} data - The JSON data to send.
     */
    public sendJson(data: object) {
        hpx.hpxWebSocketSendJson(this.id, data);
    }

    /**
     * Sends either a text message or a JSON object over the WebSocket connection based on the data type.
     * @param {string | object} data - The data to send, which can be a string or an object.
     */
    public send(data: string | object) {
        if (typeof data === "string") {
            hpx.hpxWebSocketSendText(this.id, data);
        } else {
            hpx.hpxWebSocketSendJson(this.id, data);
        }
    }

    /**
    * Closes the WebSocket connection.
    */
    public close() {
        hpx.hpxWebSocketClose(this.id);
    }
}


export class RequestModel {
    private requestModelObj;

    constructor(modelName: string, modelFields: {[key: string]: any}) {
        this.requestModelObj = {
            model: modelName,
            fields: {}
        }
    
        for (const field in modelFields) {
            const type = typeof modelFields[field]
            if (type === 'object' && modelFields[field].hasOwnProperty('model')) {
                this.requestModelObj.fields[field] = modelFields[field].model
            } else if (type === 'function') {
                continue;
            } else {
                this.requestModelObj.fields[field] = typeof modelFields[field]
            }
        }
        hpx.hpxRegisterRequestModel(modelName, this.requestModelObj.fields)
    }
}


/**
 * Represents an HTTP request.
 * @param {IRequest} req - The HTTP request object.
*/
export class Request {
    private id: string;
    public path: string;
    public method: string;
    public hostname: string;
    public body: string;
    public params: any;
    public queries: {[key: string]: string};
    public headers: {[key: string]: string};
    public cookies: {[key: string]: string};

    constructor(request: IRequest) {
        this.id = request.reqId;
        this.hostname = request.hostname;
        this.method = request.method;
        this.params = request.params;
        this.path = request.path;
        this.queries = request.queries;
        this.body = request.body;
        this.headers = request.headers;
        this.cookies = request.cookies;
    }
    
    /**
        * Sends a response to the HTTP request with optional status code and headers.
        * @param {string | number | boolean | object} data - The response data.
        * @param {number} [code=200] - The HTTP status code (default is 200).
        * @param {object} [headers] - The HTTP response headers (default is {"Content-Type": "text/plaintext"}).
     */
    public answer(data: string | number | boolean | object, code: number = 200, headers: object = {
        "Content-Type": "text/plaintext"
    }): void {
        switch (typeof data) {
            case "number":
                hpx.hpxRequestAnswerInt(this.id, data, code, headers);
                break;
            case "string":
                hpx.hpxRequestAnswerStr(this.id, data, code, headers);
                break;
            case "boolean":
                hpx.hpxRequestAnswerBool(this.id, data, code, headers);
                break;
            case "object":
                hpx.hpxRequestAnswerObj(this.id, data, code, headers);
                break;
        }
    }

    /**
     * Sends a JSON response to the HTTP request with optional status code.
     * @param {object} data - The JSON data to send.
     * @param {number} [code=200] - The HTTP status code (default is 200).
     */
    public answerJson(data: object, code: number = 200) {
        this.answer(data, code, {"Content-Type": "application/json"})
    }
    
    /**
      * Retrieves a query parameter from the HTTP request.
     * @param {string} queryKey - The name of the query parameter.
     * @returns {string | null} The value of the query parameter or null if not found.
     */
    public query(queryKey: string): string | null {
        if (queryKey in this.queries)
            return this.queries[queryKey];
        return null;
    }
}

/**
 * Creates an instance of Server.
 * @param {string} [address="127.0.0.1"] - The IP address to bind the server to (default is "127.0.0.1").
 * @param {number} [port=5000] - The port number to listen on (default is 5000).
 * 
 * @example
 * // new server at http://127.0.0.1:5000
 * const app = new Server();
 * 
 * // new server at http://0.0.0.0:80
 * const app = new Server('0.0.0.0', 80);
 */
export class Server {
    private address: string;
    private port: number;
    private serverId: number;

    constructor(
            address: string = "127.0.0.1",
            port: number = 5000,
            title: string = "HappyX NodeJS project"
    ) {
        this.address = address;
        this.port = port;
        this.serverId = hpx.hpxServer(this.address, this.port, title);
    }

    /**
     * Starts the HTTP server.
     */
    public start() {
        hpx.hpxStartServer(this.serverId);
    }

    /**
     * Defines a GET route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the GET request.
     */
    public get(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerGet(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a POST route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the POST request.
     */
    public post(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerPost(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a PUT route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the PUT request.
     */
    public put(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerPut(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a DELETE route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the DELETE request.
     */
    public delete(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerDelete(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a PATCH route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the PATCH request.
     */
    public patch(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerPatch(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }
    
    /**
     * Defines a OPTIONS route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the OPTIONS request.
     */
    public options(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerOptions(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a HEAD route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the HEAD request.
     */
    public head(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerHead(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a TRACE route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the TRACE request.
     */
    public trace(path: string, callback: (request: Request) => any, docs: string = "") {
        hpx.hpxServerTrace(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a COPY route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the TRACE request.
     */
    public copy(path: string, callback: (request: Request) => any, docs: string = ""): void {
        hpx.hpxServerCopy(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a PURGE route on the server.
     * @param {string} path - The route path.
     * @param {(request: Request) => any} callback - The callback function to handle the TRACE request.
     */
    public purge(path: string, callback: (request: Request) => any, docs: string = ""): void {
        hpx.hpxServerPurge(this.serverId, path, (req: IRequest) => {
            return callback(new Request(req));
        }, docs);
    }

    /**
     * Defines a middleware route on the server.
     * @param {(request: Request) => any} callback - The callback function to handle all HTTP requests.
     */
    public middleware(callback: (request: Request) => any): void {
        hpx.hpxServerMiddleware(this.serverId, (req: IRequest) => {
            return callback(new Request(req));
        });
    }

    /**
     * Defines a route on the server that touches when not any routes matched.
     * @param {(request: Request) => any} callback - The callback function to handle the 404 route.
     */
    public notfound(callback: (request: Request) => any) {
        hpx.hpxServerNotFound(this.serverId, (req: IRequest) => {
            return callback(new Request(req));
        });
    }

    /**
    * Defines a WebSocket route on the server.
     * @param {string} path - The route path.
     * @param {(wsClient: WebSocketClient) => any} callback - The callback function to handle WebSocket connections.
    */
    public ws(path: string, callback: (wsClient: WebSocketClient) => any) {
        let wsClient: WebSocketClient;
        hpx.hpxServerWebSocket(this.serverId, path, (req: IWebSocket) => {
            if (!wsClient) {
                wsClient = new WebSocketClient(req);
            }
            wsClient.setState(req.state);
            callback(wsClient);
        });
    }

    /**
    * Defines a WebSocket route on the server.
     * @param {string} path - The route path.
     * @param {(wsClient: WebSocketClient) => any} callback -
     *        The callback function to handle WebSocket connections.
     * 
     * @example
     *  asdasdasdasdasdsa;
     * 
     */
    public mount(path: string, other: Server) {
        hpx.hpxServerMount(this.serverId, path, other.serverId);
    }

    /**
     * Serves static files from a directory under a specific path.
     * @param {string} path - The route path.
     * @param {string} directory - The directory to serve static files from.
     */
    public static(path: string, directory: string) {
        hpx.hpxServerStatic(this.serverId, path, directory);
    }
}


export function newPathParamType(name: string, pattern: string | RegExp, cb: (data: string) => any) {
    if (typeof pattern === "string" ) {
        hpx.hpxRegisterPathParamType(name, pattern, cb);
    } else {
        hpx.hpxRegisterPathParamType(name, pattern.source, cb);
    }
}
