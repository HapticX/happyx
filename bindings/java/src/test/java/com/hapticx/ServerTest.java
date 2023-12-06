package com.hapticx;

import com.hapticx.data.HttpHeader;
import com.hapticx.data.Queries;
import com.hapticx.data.Query;
import org.junit.Test;

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