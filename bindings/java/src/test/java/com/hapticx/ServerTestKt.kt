package com.hapticx

import com.google.gson.Gson
import com.hapticx.data.HttpHeader
import com.hapticx.response.BaseResponse
import com.hapticx.response.FileResponse
import com.hapticx.response.HtmlResponse
import com.hapticx.response.JsonResponse
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

        s.get("/base") {
            println(it.path)
            return@get BaseResponse(
                "Oops, bad request",
                401,
                listOf(HttpHeader("Programming-Language", "Kotlin"))
            )
        }

        s.get("/html") {
            println(it.path)
            return@get HtmlResponse(
                "<h1>Oops! Seems like page that you search is not found</h1>",
                404,
                listOf(HttpHeader("Programming-Language", "Kotlin"))
            )
        }

        s.get("/json") {
            println(it.path)
            return@get JsonResponse(
                Gson().toJson(listOf(1, 2, 3)),
                404,
                listOf(HttpHeader("Programming-Language", "Kotlin"))
            )
        }

        s.get("/file") {
            println(it.path)
            return@get FileResponse(Server::class.java.getResource("/happyx.dll")!!.file)
        }

        s.route("/any", listOf("GET", "POST")) {
            return@route "You can see it only on GET or POST"
        }

        println(System.getProperty("user.dir"))
        s.staticDirectory("/staticDirectory", System.getProperty("user.dir"))

        s.start()
    }
}