package com.hapticx.util;

import java.util.Locale;

public final class OS {
    /**
     * types of Operating Systems
     */
    public enum Type {
        Windows, MacOS, Linux, Other
    }

    // cached result of OS detection
    static Type detectedOS;

    /**
     * detect the operating system from the os.name System property and cache
     * the result
     *
     * @return - the operating system detected
     */
    public static Type getOperatingSystemType() {
        if (detectedOS == null) {
            String OS = System.getProperty("os.name", "generic").toLowerCase(Locale.ENGLISH);
            if ((OS.contains("mac")) || (OS.contains("darwin"))) {
                detectedOS = Type.MacOS;
            } else if (OS.contains("win")) {
                detectedOS = Type.Windows;
            } else if (OS.contains("nux")) {
                detectedOS = Type.Linux;
            } else {
                detectedOS = Type.Other;
            }
        }
        return detectedOS;
    }
}