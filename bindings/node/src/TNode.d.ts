// node.node types

export interface IRequest {
    reqId: string
    body: string
    hostname: string
    method: string
    path: string
    params: any
    queries: {[key: string]: string}
    cookies: {[key: string]: string}
    headers: {[key: string]: string}
}

export interface IWebSocket {
    path: string
    websocketId: string
    data: string
    state: "wssConnect" | "wssOpen" | "wssClose" | "wssHandshakeError" | "wssMismatchProtocol" | "wssError"  // should be enum
}

export type TServerPathCB = (serverId: number, path: string, callback: any, docs: string) => any;
export type TServerCB = (serverId: number, callback: any) => any;

export interface TCore {
    // Constants
    /**
     * HappyX web framework version
     */
    hpxVersion: string

    // Constructors
    /**
     * Creates a new HappyX web server
     * @param address web server address
     * @param port web server port
     * @returns web server unique ID
     */
    hpxServer: (address: string, port: number, title: string) => number

    // Server functions
    hpxServerGet: TServerPathCB
    hpxServerPost: TServerPathCB
    hpxServerLink: TServerPathCB
    hpxServerPurge: TServerPathCB
    hpxServerTrace: TServerPathCB
    hpxServerOptions: TServerPathCB
    hpxServerPatch: TServerPathCB
    hpxServerPut: TServerPathCB
    hpxServerDelete: TServerPathCB
    hpxServerHead: TServerPathCB
    hpxServerCopy: TServerPathCB
    hpxServerMiddleware: TServerCB
    hpxServerNotFound: TServerCB
    hpxServerWebSocket: (serverId: number, path: string, callback: any) => void
    hpxServerRoute: (serverId: number, httpMethods: Array<string>, path: string, callback: any, docs: string) => void
    hpxStartServer: (serverId: number) => void
    hpxServerMount: (serverId: number, path: string, otherServerId: number) => void
    hpxServerStatic: (serverId: number, path: string, directory: string) => void

    // WebSocket functions
    hpxWebSocketClose: (wsId: string) => void
    hpxWebSocketSendText: (wsId: string, data: string) => void
    hpxWebSocketSendJson: (wsId: string, data: object) => void

    // Request functions
    hpxRequestAnswerStr: (reqId: string, data: string, code: number, headers: object) => void
    hpxRequestAnswerInt: (reqId: string, data: number, code: number, headers: object) => void
    hpxRequestAnswerBool: (reqId: string, data: boolean, code: number, headers: object) => void
    hpxRequestAnswerObj: (reqId: string, data: object, code: number, headers: object) => void

    // Request Models functions
    hpxRegisterRequestModel: (modelName: string, reqModel: Array<{[key: string]: string}>) => void

    // Register Path Param Type
    hpxRegisterPathParamType: (name: string, pattern: string, cb: (data: string) => any) => void
}
