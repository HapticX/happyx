package com.hapticx.util;

import com.hapticx.Server;

import java.net.URL;

/**
 * A utility class for loading native libraries based on the operating system.
 */
public class LibLoader {
    /**
     * Loads the specified native library based on the operating system.
     *
     * @param library The name of the native library (excluding the file extension).
     */
    public static void load(String library) {
        try {
            // Determine the file extension based on the operating system
            String extension = switch (OS.getOperatingSystemType()) {
                case Windows -> ".dll";
                case MacOS, Linux -> ".so";
                default -> throw new IllegalStateException(
                        "Unexpected value: " + System.getProperty("os.name").toLowerCase()
                );
            };

            // Construct the URL for the native library
            URL url = Server.class.getResource("/" + library + extension);
            assert url != null;

            // Load the native library
            System.load(url.getFile());
        } catch (Exception e) {
            // Print the stack trace if an exception occurs during the library loading process
            e.printStackTrace();
        }
    }
}