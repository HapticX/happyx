package com.hapticx.data;


import java.util.List;

public class PathParam {
    private final String name;
    private final Object value;

    public PathParam(String name, Object value) {
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, int value) {
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, float value) {
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, boolean value) {
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, String value) {
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, PathParams value) {
        this.name = name;
        this.value = value;
    }

    public PathParam(String name, PathParamMap value) {
        this.name = name;
        this.value = value;
    }

    public Object getValue() {
        return value;
    }

    public String getTypeName() {
        return value.getClass().getName();
    }

    public Class<?> getType() {
        return value.getClass();
    }

    public int getInt() {
        if (value instanceof Integer) {
            return (int) value;
        }
        throw new IllegalStateException("Cannot get integer from " + getType());
    }

    public float getFloat() {
        if (value instanceof Float) {
            return (float) value;
        }
        throw new IllegalStateException("Cannot get float from " + getType());
    }

    public boolean getBoolean() {
        if (value instanceof Boolean) {
            return (boolean) value;
        }
        throw new IllegalStateException("Cannot get boolean from " + getType());
    }

    public String getString() {
        if (value instanceof String) {
            return (String) value;
        }
        throw new IllegalStateException("Cannot get String from " + getType());
    }

    public PathParams getList() {
        if (value instanceof PathParams) {
            return (PathParams) value;
        }
        throw new IllegalStateException("Cannot get List from " + getType());
    }

    public <T> T getAs(Class<T> cls) {
        if (value != null && value.getClass() == cls) {
            return (T)value;
        }
        throw new IllegalStateException("Cannot get " + cls.getName() + " from " + getType());
    }

    public PathParamMap getMap() {
        if (value instanceof PathParamMap) {
            return (PathParamMap) value;
        }
        throw new IllegalStateException("Cannot get List from " + getType());
    }

    public PathParam get(String name) {
        if (value instanceof PathParamMap) {
            return ((PathParamMap) value).get(name);
        }
        return null;
    }

    public PathParam get(int index) {
        if (value instanceof PathParams) {
            return ((PathParams) value).get(index);
        }
        return null;
    }

    public String getName() {
        return name;
    }

    @Override
    public String toString() {
        return switch (getTypeName()) {
            case "java.lang.Integer" -> Integer.toString((int) value);
            case "java.lang.Float" -> Float.toString((float) value);
            case "java.lang.Boolean" -> Boolean.toString((boolean) value);
            case "java.lang.String" -> "\"" + value + "\"";
            default -> value.toString();
        };
    }
}
