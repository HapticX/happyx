package com.hapticx.util;

import com.hapticx.Server;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class LibLoader {
    public static void load(String library) {
        try {
            String extension;
            // load from resources
            OS.Type osType = OS.getOperatingSystemType();
            switch (osType) {
                case Windows -> extension = ".dll";
                case MacOS, Linux -> extension = ".so";
                default -> {
                    extension = "";
                    throw new IllegalStateException("Unexpected value: " + System.getProperty("os.name").toLowerCase());
                }
            }
            InputStream is = Server.class.getResourceAsStream("/" + library + extension);

            // create temporary file
            File file = File.createTempFile(library, extension);
            file.deleteOnExit();

            // write lib
            try (FileOutputStream fos = new FileOutputStream(file)) {
                byte[] buffer = new byte[1024];
                int readBytes;
                if (is != null) {
                    while ((readBytes = is.read(buffer)) != -1) {
                        fos.write(buffer, 0, readBytes);
                    }
                }
            }

            // load lib
            System.load(file.getAbsolutePath());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
