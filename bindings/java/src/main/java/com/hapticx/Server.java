package com.hapticx;


import com.hapticx.data.HttpRequest;
import com.hapticx.util.LibLoader;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

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
    private native void post(int serverId, String path, RequestCallback cb);
    private native void put(int serverId, String path, RequestCallback cb);
    private native void delete(int serverId, String path, RequestCallback cb);
    private native void purge(int serverId, String path, RequestCallback cb);
    private native void copy(int serverId, String path, RequestCallback cb);
    private native void head(int serverId, String path, RequestCallback cb);
    private native void link(int serverId, String path, RequestCallback cb);
    private native void unlink(int serverId, String path, RequestCallback cb);
    private native void options(int serverId, String path, RequestCallback cb);
    private native void route(int serverId, String path, List<String> methods, RequestCallback cb);
    private native void notFound(int serverId, RequestCallback cb);
    private native void middleware(int serverId, RequestCallback cb);
    private native void staticDirectory(
            int serverId, String path, String directory, List<String> extensions
    );

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

    public void post(String path, RequestCallback cb) {
        post(this.serverId, path, cb);
    }

    public void purge(String path, RequestCallback cb) {
        purge(this.serverId, path, cb);
    }

    public void delete(String path, RequestCallback cb) {
        delete(this.serverId, path, cb);
    }

    public void put(String path, RequestCallback cb) {
        put(this.serverId, path, cb);
    }

    public void copy(String path, RequestCallback cb) {
        copy(this.serverId, path, cb);
    }

    public void head(String path, RequestCallback cb) {
        head(this.serverId, path, cb);
    }

    public void link(String path, RequestCallback cb) {
        link(this.serverId, path, cb);
    }

    public void unlink(String path, RequestCallback cb) {
        unlink(this.serverId, path, cb);
    }

    public void options(String path, RequestCallback cb) {
        options(this.serverId, path, cb);
    }

    public void route(String path, List<String> methods, RequestCallback cb) {
        route(this.serverId, path, methods, cb);
    }

    public void route(String path, String[] methods, RequestCallback cb) {
        route(this.serverId, path, Arrays.asList(methods), cb);
    }

    public void notFound(RequestCallback cb) {
        notFound(this.serverId, cb);
    }

    public void middleware(RequestCallback cb) {
        middleware(this.serverId, cb);
    }

    public void staticDirectory(String path, String directory, List<String> extensions) {
        staticDirectory(this.serverId, path, directory, extensions);
    }

    public void staticDirectory(String path, String directory,String[] extensions) {
        staticDirectory(this.serverId, path, directory, Arrays.asList(extensions));
    }

    public void staticDirectory(String directory, List<String> extensions) {
        staticDirectory(this.serverId, directory, directory, extensions);
    }

    public void staticDirectory(String directory, String[] extensions) {
        staticDirectory(this.serverId, directory, directory, Arrays.asList(extensions));
    }

    public void staticDirectory(String directory) {
        staticDirectory(this.serverId, directory, directory, null);
    }

    public void staticDirectory(String path, String directory) {
        staticDirectory(this.serverId, path, directory, null);
    }

    public void start() {
        startServer(this.serverId);
    }
}
