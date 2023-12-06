package com.hapticx

import org.junit.Test

class ServerTestKt {

    @Test
    fun testServer() {
        val s = Server()

        s.get("/") {
            // Just print path
            println(it.path)
            0
        }

        s.get("/user{userId:int}") {
            // Get path
            println(it.path)

            // Get any path param that you registered
            println(it.pathParams["userId"].int + 10)

            // Iterate over all queries
            println("Queries:")
            for (i in it.queries) {
                println(i)
            }

            // Iterate over all HttpHeaders
            println("HTTP Headers:")
            for (i in it.headers) {
                println(i)
            }

            // answer to request
            // now it sends just like string
            return@get "Hello, world!"
        }

        s.start()
    }
}