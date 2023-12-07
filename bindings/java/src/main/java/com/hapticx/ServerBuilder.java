package com.hapticx;


import java.util.List;

public class ServerBuilder {
    private final Server server;

    public ServerBuilder(String path, int port) {
        this.server = new Server(path, port);
    }

    public ServerBuilder(String path) {
        this.server = new Server(path, 5000);
    }

    public ServerBuilder(int port) {
        this.server = new Server("127.0.0.1", port);
    }

    public ServerBuilder() {
        this.server = new Server("127.0.0.1", 5000);
    }

    public ServerBuilder get(String path, Server.RequestCallback cb) {
        this.server.get(path, cb);
        return this;
    }

    public ServerBuilder post(String path, Server.RequestCallback cb) {
        this.server.post(path, cb);
        return this;
    }

    public ServerBuilder delete(String path, Server.RequestCallback cb) {
        this.server.delete(path, cb);
        return this;
    }

    public ServerBuilder put(String path, Server.RequestCallback cb) {
        this.server.put(path, cb);
        return this;
    }

    public ServerBuilder purge(String path, Server.RequestCallback cb) {
        this.server.purge(path, cb);
        return this;
    }

    public ServerBuilder link(String path, Server.RequestCallback cb) {
        this.server.link(path, cb);
        return this;
    }

    public ServerBuilder unlink(String path, Server.RequestCallback cb) {
        this.server.unlink(path, cb);
        return this;
    }

    public ServerBuilder copy(String path, Server.RequestCallback cb) {
        this.server.copy(path, cb);
        return this;
    }

    public ServerBuilder head(String path, Server.RequestCallback cb) {
        this.server.head(path, cb);
        return this;
    }

    public ServerBuilder options(String path, Server.RequestCallback cb) {
        this.server.options(path, cb);
        return this;
    }

    public ServerBuilder websocket(String path, Server.WebSocketCallback cb) {
        this.server.websocket(path, cb);
        return this;
    }

    public ServerBuilder middleware(Server.RequestCallback cb) {
        this.server.middleware(cb);
        return this;
    }

    public ServerBuilder notFound(Server.RequestCallback cb) {
        this.server.notFound(cb);
        return this;
    }

    public ServerBuilder route(String path, List<String> methods, Server.RequestCallback cb) {
        this.server.route(path, methods, cb);
        return this;
    }

    public ServerBuilder route(String path, String[] methods, Server.RequestCallback cb) {
        this.server.route(path, methods, cb);
        return this;
    }

    public ServerBuilder staticDirectory(String path, String directory, List<String> extensions) {
        this.server.staticDirectory(path, directory, extensions);
        return this;
    }

    public ServerBuilder staticDirectory(String path, String directory) {
        this.server.staticDirectory(path, directory);
        return this;
    }

    public ServerBuilder staticDirectory(String directory, List<String> extensions) {
        this.server.staticDirectory(directory, extensions);
        return this;
    }

    public ServerBuilder staticDirectory(String directory) {
        this.server.staticDirectory(directory);
        return this;
    }

    public ServerBuilder mount(String path, Server server) {
        this.server.mount(path, server);
        return this;
    }

    public void start() {
        this.server.start();
    }

    public Server build() {
        return this.server;
    }
}
