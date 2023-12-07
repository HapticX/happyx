package com.hapticx

fun server(hostname: String = "127.0.0.1", port: Int = 5000, init: Server.() -> Unit): Server {
    val server = Server(hostname, port)
    server.init()
    return server
}
