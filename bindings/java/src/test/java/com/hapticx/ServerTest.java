package com.hapticx;

import com.hapticx.data.HttpHeader;
import com.hapticx.data.HttpHeaders;
import com.hapticx.data.Queries;
import com.hapticx.data.Query;
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
            System.out.println(req.getPathParams().get("userId").getInt() + 10);

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

        s.start();
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
}