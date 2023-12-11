package com.hapticx

import com.hapticx.data.PathParam

fun server(hostname: String = "127.0.0.1", port: Int = 5000, init: Server.() -> Unit): Server {
    val server = Server(hostname, port)
    server.init()
    return server
}

inline fun <reified T> PathParam.get(): T {
    if (value != null && value is T) {
        return value as T
    }
    throw IllegalStateException("Cannot get ${T::class.java.name} from $type")
}

inline fun <reified T> PathParam.getAs(name: String): T {
    val res = get(name)
    if (res != null && res is T) {
        return res
    }
    throw IllegalStateException("Cannot get ${T::class.java.name} from $type")
}
