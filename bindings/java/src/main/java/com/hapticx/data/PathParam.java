package com.hapticx.data;


public class PathParam {
    private final String name;
    private final Object value;

    enum Type {
        INTEGER, FLOAT, BOOLEAN, STRING, LIST, OBJECT
    }

    private final Type type;

    public PathParam(String name, int value) {
        this.type = Type.INTEGER;
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, float value) {
        this.type = Type.FLOAT;
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, boolean value) {
        this.type = Type.BOOLEAN;
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, String value) {
        this.type = Type.STRING;
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, PathParams value) {
        this.type = Type.LIST;
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, PathParamMap value) {
        this.type = Type.OBJECT;
        this.name = name;
        this.value = value;
    }

    public Object getValue() {
        return value;
    }

    public int getInt() {
        if (this.type == Type.INTEGER) {
            return (int) this.value;
        }
        throw new IllegalStateException("Cannot get integer from " + this.type);
    }

    public float getFloat() {
        if (this.type == Type.FLOAT) {
            return (float) this.value;
        }
        throw new IllegalStateException("Cannot get float from " + this.type);
    }

    public boolean getBoolean() {
        if (this.type == Type.FLOAT) {
            return (boolean) this.value;
        }
        throw new IllegalStateException("Cannot get boolean from " + this.type);
    }

    public String getString() {
        if (this.type == Type.STRING) {
            return (String) this.value;
        }
        throw new IllegalStateException("Cannot get String from " + this.type);
    }

    public PathParams getList() {
        if (this.type == Type.LIST) {
            return (PathParams) this.value;
        }
        throw new IllegalStateException("Cannot get List from " + this.type);
    }

    public PathParamMap getMap() {
        if (this.type == Type.OBJECT) {
            return (PathParamMap) this.value;
        }
        throw new IllegalStateException("Cannot get List from " + this.type);
    }

    public PathParam get(String name) {
        if (this.type == Type.OBJECT) {
            return ((PathParamMap) this.value).get(name);
        }
        return null;
    }

    public PathParam get(int index) {
        if (this.type == Type.LIST) {
            return ((PathParams) this.value).get(index);
        }
        return null;
    }

    public String getName() {
        return name;
    }

    public Type getType() {
        return type;
    }

    @Override
    public String toString() {
        return switch (type) {
            case INTEGER -> Integer.toString((int) value);
            case FLOAT -> Float.toString((float) value);
            case BOOLEAN -> Boolean.toString((boolean) value);
            case STRING -> "\"" + value + "\"";
            case LIST, OBJECT -> value.toString();
        };
    }
}
