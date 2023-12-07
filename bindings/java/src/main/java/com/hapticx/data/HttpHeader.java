package com.hapticx.data;

/**
 * Represents an HTTP header with a key and a value.
 */
public class HttpHeader {

    private final String key;
    private final String value;

    /**
     * Constructs an HTTP header with the specified key and value.
     *
     * @param key   The key of the header.
     * @param value The value of the header.
     */
    public HttpHeader(String key, String value) {
        this.key = key;
        this.value = value;
    }

    /**
     * Gets the value of the HTTP header.
     *
     * @return The value of the header.
     */
    public String getValue() {
        return value;
    }

    /**
     * Gets the key of the HTTP header.
     *
     * @return The key of the header.
     */
    public String getKey() {
        return key;
    }

    /**
     * Returns a string representation of the HTTP header.
     *
     * @return A string representation of the object.
     */
    @Override
    public String toString() {
        return "HttpHeader{" +
                "key='" + key + '\'' +
                ", value='" + value + '\'' +
                '}';
    }
}