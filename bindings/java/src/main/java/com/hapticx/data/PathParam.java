package com.hapticx.data;

public class PathParam {
    private final String name;
    private final Object value;

    enum Type {
        INTEGER, FLOAT, BOOLEAN, STRING
    }

    private final Type type;

    public PathParam(String name, Object value, String type) {
        this.name = name;
        this.value = value;

        switch (type) {
            case "int" -> this.type = Type.INTEGER;
            case "float" -> this.type = Type.FLOAT;
            case "bool" -> this.type = Type.BOOLEAN;
            default -> this.type = Type.STRING;
        }
    }

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

    public Object getValue() {
        return value;
    }

    public int getInt() {
        if (this.type == Type.INTEGER) {
            return (int)this.value;
        }
        throw new IllegalStateException("Cannot get integer from " + this.type);
    }

    public float getFloat() {
        if (this.type == Type.FLOAT) {
            return (float)this.value;
        }
        throw new IllegalStateException("Cannot get float from " + this.type);
    }

    public boolean getBoolean() {
        if (this.type == Type.FLOAT) {
            return (boolean)this.value;
        }
        throw new IllegalStateException("Cannot get boolean from " + this.type);
    }

    public String getString() {
        if (this.type == Type.FLOAT) {
            return (String)this.value;
        }
        throw new IllegalStateException("Cannot get String from " + this.type);
    }

    public String getName() {
        return name;
    }

    public Type getType() {
        return type;
    }
}
