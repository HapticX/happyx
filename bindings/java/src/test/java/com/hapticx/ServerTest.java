package com.hapticx;

import com.hapticx.data.*;
import com.hapticx.response.BaseResponse;
import com.hapticx.response.FileResponse;
import com.hapticx.response.HtmlResponse;
import org.junit.Test;

import java.util.Objects;

public class ServerTest {

    @Test
    public void testServer() {
        Server s = new Server();

        s.get("/", req -> {
            // Just print path
            System.out.println(req.getPath());
            return 0;
        });

        s.get("/user{userId:int}", req -> {
            // Get path
            System.out.println(req.getPath());

            // Get any path param that you registered
            System.out.println(req.getParams().get("userId").getInt() + 10);

            // Iterate over all queries
            System.out.println("Queries:");
            for (Query i : req.getQueries()) {
                System.out.println(i);
            }

            // Iterate over all HttpHeaders
            System.out.println("HTTP Headers:");
            for (HttpHeader i : req.getHeaders()) {
                System.out.println(i);
            }

            // answer to request
            // now it sends just like string
            return "Hello, world!";
        });

        s.get("/base", req -> {
            System.out.println(req.getPath());
            HttpHeaders headers = new HttpHeaders();
            headers.add(new HttpHeader("Programming-Language", "Kotlin"));
            return new BaseResponse(
                    "Oops, bad request",
                    401,
                    headers
            );
        });

        s.get("/html", req -> {
            System.out.println(req.getPath());
            HttpHeaders headers = new HttpHeaders();
            headers.add(new HttpHeader("Programming-Language", "Kotlin"));
            return new HtmlResponse(
                    "<h1>Oops! Seems like page that you search is not found</h1>",
                    404,
                    headers
            );
        });

        s.get("/file", req -> {
            System.out.println(req.getPath());
            return new FileResponse(
                    Objects.requireNonNull(Server.class.getResource("/happyx.dll"))
                            .getFile()
            );
        });

        s.route("/any", new String[]{"GET", "POST"}, req -> "You can see it only on GET or POST");

        System.out.println(System.getProperty("user.dir"));
        s.staticDirectory("/staticDirectory", System.getProperty("user.dir"));

        Server settings = new Server();
        s.mount("/settings", settings);

        settings.get("/", req -> "Hello from settings mount");

        s.websocket("/ws", ws -> {
            if (ws.getState() == WSConnection.State.OPEN) {
                if (ws.getData().equals("close")) {
                    ws.send("bye");
                    ws.close();
                } else {
                    ws.send("Hello!");
                }
            }
        });

        BaseRequestModel.register(new Message());
        BaseRequestModel.register(new Chat());
        s.post("/user[u:Message]", req -> {
            System.out.println(req.getParams());
            System.out.println(req.getParams().getMap().get("u"));
            System.out.println(req.getParams().getMap().get("u").getMap().get("text"));
            System.out.println(req.getParams().getMap().get("u").getMap().get("text").getString());
            req.answer("Hello, world!");
            return null;
        });


//         s.start(); // uncomment it to run server
    }

    @Test
    public void builderTest() {
        new ServerBuilder()
                .get("/", req -> "Hello, world!")
                .get("/html", req -> new HtmlResponse("<h1>Header</h1>"));
                // .start();
    }

    @Test
    public void queriesTest() {
        Query q = new Query("a", "b");
        Queries qs = new Queries();
        qs.add(q);
        for (Query query : qs) {
            System.out.println(query.getKey());
        }
    }

    static class Message extends BaseRequestModel {
        public String text;
    }

    static class Chat extends Message {
        public String author;
    }
}