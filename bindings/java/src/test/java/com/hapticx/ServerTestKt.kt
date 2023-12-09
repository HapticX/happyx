package com.hapticx

import com.google.gson.Gson
import com.hapticx.data.BaseRequestModel
import com.hapticx.data.HttpHeader
import com.hapticx.data.HttpRequest
import com.hapticx.data.WSConnection
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
            println(it.params["userId"].int + 10)

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

        val settings = Server()
        s.mount("/settings", settings)

        settings.get("/") {
            return@get "Hello from settings mount"
        }

        s.websocket("/ws") {
            if (it.state == WSConnection.State.OPEN) {
                if (it.data == "close") {
                    it.send("bye")
                    it.close()
                } else {
                    it.send("Hello!")
                }
            }
        }

        BaseRequestModel.register(ServerTest.Message())
        BaseRequestModel.register(ServerTest.Chat())
        s.post("/user[u:Message]") { req: HttpRequest ->
            println(req.params)
            println(req.params.map["u"])
            println(req.params.map["u"]!!.map["text"])
            println(req.params.map["u"]!!.map["text"]!!.string)
            null
        }

        // uncomment it to run server
        // s.start()
    }

    @Test
    fun withDsl() {
        server("127.0.0.0", 5000) {
            get("/") {
                return@get "Hello, world!"
            }

            route("/some", listOf("GET", "POST")) {
                return@route "Hello, world!"
            }

            // uncomment it to run server
            // start()
        }
    }

    internal open class Message : BaseRequestModel() {
        var text: String? = null
    }

    internal class Chat : Message() {
        var author: String? = null
    }
}