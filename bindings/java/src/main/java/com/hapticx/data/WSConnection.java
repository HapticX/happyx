package com.hapticx.data;

import com.hapticx.util.LibLoader;

public class WSConnection {
    public enum State {
        CONNECT,
        OPEN,
        CLOSE,
        HANDSHAKE_ERROR,
        MISMATCH_PROTOCOL,
        ERROR
    }

    static {
        LibLoader.load("happyx");
    }

    private native void close(String id);
    private native void send(String id, String data);

    private final String id;
    private final String data;
    private final State state;

    public WSConnection(String id, String data, State state) {
        this.id = id;
        this.data = data;
        this.state = state;
    }

    public void send(String data) {
        send(this.id, data);
    }

    public void close() {
        close(this.id);
    }

    public String getData() {
        return data;
    }

    public State getState() {
        return state;
    }
}
