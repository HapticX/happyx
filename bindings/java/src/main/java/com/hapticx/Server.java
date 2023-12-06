package com.hapticx;


import com.hapticx.data.HttpRequest;
import com.hapticx.util.LibLoader;

public class Server {
    static {
        LibLoader.load("happyx");
    }

    public interface RequestCallback {
        Object onRequest(HttpRequest req);
    }

    private native int createServer(String hostname, int port);
    private native void startServer(int serverId);
    private native void get(int serverId, String path, RequestCallback cb);

    private final int serverId;

    public Server() {
        this.serverId = createServer("127.0.0.1", 5000);
    }

    public Server(String hostname) {
        this.serverId = createServer(hostname, 5000);
    }

    public Server(int port) {
        this.serverId = createServer("127.0.0.1", port);
    }

    public Server(String hostname, int port) {
        this.serverId = createServer(hostname, port);
    }

    public void get(String path, RequestCallback cb) {
        get(this.serverId, path, cb);
    }

    public void start() {
        startServer(this.serverId);
    }
}
