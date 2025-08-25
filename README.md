# Manual Android NDK App Build Guide

I just hate grade and jave build system, This Repo is a refrence to building an android app manually using android Ndk (optionally) and the android Sdk.

This Repo outlines the complete process for compiling, packaging, and signing an Android NDK application from the command line, without relying on Gradle or an IDE.

The repo contains all the necessary source files that you will need if you don't feel like creating them, it also has the final .apk file for you to try installing the final app build.

The repo also contains build.sh that automates the building process for you.

## 1. Version Information

The Ndk and Sdk version used for the build in this repo are as follows:

### NDK Version: 27.3.13750724

The NDK version `27.3.13750724` corresponds to **NDK r27c**. The build process will use tools from this specific NDK package.

### SDK Versions: (35.0.0)

- **Platform:** `android-35`
- **Build Tools:** `35.0.0`

All SDK-related commands will use tools from these specific versions.

## 2. Project Setup

Before starting the build, we need to set up the project's directory structure and environment variables.

### Directory Structure

Create the following directories from the root of your project:

```bash
mkdir -p src/com/example/myndkapp res/layout res/values jni libs bin obj build
```

- `src/com/example/myndkapp`: For your Java source files.
- `res/layout`: For your layout XML files.
- `res/values`: For your string and resource value XML files.
- `jni`: For your native C/C++ source files.
- `libs`: Will hold the compiled native libraries.
- `bin`: Will hold intermediate and final APK files.
- `obj`: Will hold compiled Java `.class` files.
- `build`: A temporary directory for packaging native libraries.

### Environment Variables

You must export the following environment variables in your terminal session. These point to the locations of your Android SDK and NDK tools. Replace the placeholder with the actual path to your Android SDK installation.

```bash
export ANDROID_HOME=<path to your Android SDK>
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.3.13750724 #the final dir name is different according to your Ndk version
export PLATFORM=$ANDROID_HOME/platforms/android-35 #the final dir name is different according to your Sdk version
export BUILD_TOOLS=$ANDROID_HOME/build-tools/35.0.0 #the final dir name is different according to your Sdk version
```

## 3. Prepare Your Files

Create the following files in their respective directories with the content provided.

### AndroidManifest.xml

First, create the file in the root of your project.
```bash
touch AndroidManifest.xml
```
Then, add the following content. This file describes essential information about your app to the Android build tools, the Android operating system, and Google Play.

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="[http://schemas.android.com/apk/res/android](http://schemas.android.com/apk/res/android)"
    package="com.example.myndkapp">

    <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="34" />

    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

### jni/native-lib.cpp

First, create the file.
```bash
touch jni/native-lib.cpp
```
Then, add the following content. This is the C++ source file containing the native function that will be called from Java.

```cpp
#include <jni.h>

/*
 * This is the C++ function that will be called from Java.
 * The name must be exact: Java_packagename_ClassName_methodName
 */
extern "C" JNIEXPORT jint JNICALL
Java_com_example_myndkapp_MainActivity_addNumbers(
        JNIEnv* env,
        jobject /* this */,
        jint a,
        jint b) {
    return a + b;
}
```

### src/com/example/myndkapp/MainActivity.java

First, create the file.
```bash
touch src/com/example/myndkapp/MainActivity.java
```
Then, add the following content. This is the main entry point for your app's user interface.

```java
package com.example.myndkapp;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends Activity {

    // Load our native library. The name must match the library
    // we will compile.
    static {
        System.loadLibrary("native-lib");
    }

    // Declare the native method that is implemented in C++
    public native int addNumbers(int a, int b);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Use the generated R.id constant directly to find the TextView.
        TextView resultTextView = findViewById(R.id.result_textview);

        // Call the native C++ function
        int result = addNumbers(5, 7);

        // Display the result
        resultTextView.setText("5 + 7 = " + result);
    }
}
```

### res/layout/activity_main.xml

First, create the file.
```bash
touch res/layout/activity_main.xml
```
Then, add the following content. This XML file defines the layout for your main activity's UI.

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="[http://schemas.android.com/apk/res/android](http://schemas.android.com/apk/res/android)"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center">

    <TextView
        android:id="@+id/result_textview"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="24sp"
        android:text="Calculating..." />

</LinearLayout>
```

### res/values/strings.xml

First, create the file.
```bash
touch res/values/strings.xml
```
Then, add the following content. This file contains string resources for your app, such as the app name.

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Manual NDK App</string>
</resources>
```

## 4. Step-by-Step Build Process

Follow these steps in order to build the application.

### Step 1: Compile Native C++ Code

This command uses the `clang++` compiler from the NDK to compile your C++ source code into a shared library (`.so`).

```bash
$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++ \
    -shared \
    -o libs/arm64-v8a/libnative-lib.so \
    jni/native-lib.cpp
```

### Step 2: Compile Resources

This command uses `aapt2` to compile your application's resources into an efficient binary format.

```bash
$BUILD_TOOLS/aapt2 compile --dir res -o bin/compiled_res.zip
```

### Step 3: Link Resources & Generate R.java

This command links the compiled resources with your `AndroidManifest.xml` and generates the `R.java` file.

```bash
$BUILD_TOOLS/aapt2 link \
    -o bin/base.apk \
    --manifest AndroidManifest.xml \
    -I "$PLATFORM/android.jar" \
    --java src \
    bin/compiled_res.zip
```

### Step 4: Compile Java Sources

This command uses `javac` to compile your `.java` files into Java bytecode (`.class` files).

```bash
javac -d obj \
    -classpath "$PLATFORM/android.jar" \
    src/com/example/myndkapp/*.java
```

### Step 5: Convert to DEX Format

This command uses `d8` to convert the Java `.class` files into a single `classes.dex` file.

```bash
$BUILD_TOOLS/d8 obj/com/example/myndkapp/*.class \
    --output bin \
    --lib "$PLATFORM/android.jar"
```

### Step 6: Package the APK

These commands assemble all the compiled components into a single APK file.

```bash
# Copy the resource-only base.apk to create our working package.
cp bin/base.apk bin/unaligned_app.apk

# Add the compiled Java code to the root of the archive.
zip -uj bin/unaligned_app.apk bin/classes.dex

# Add your native library and its C++ dependency to the correct path inside the APK.
mkdir -p build/lib/arm64-v8a
cp libs/arm64-v8a/libnative-lib.so build/lib/arm64-v8a/
cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" build/lib/arm64-v8a/
(cd build && zip -r ../bin/unaligned_app.apk lib)
```

### Step 7: Align the APK

This optimization step uses `zipalign` to ensure all uncompressed data within the APK is aligned.

```bash
$BUILD_TOOLS/zipalign -v 4 bin/unaligned_app.apk bin/MyNdkApp-final.apk
```

### Step 8: Sign the APK

This final step uses `apksigner` to cryptographically sign the APK with a debug key.

```bash
$BUILD_TOOLS/apksigner sign \
    --ks debug.keystore \
    --ks-pass pass:android \
    --out bin/MyNdkApp-signed.apk \
    bin/MyNdkApp-final.apk
```

## 5. Installation

The build is now complete. The final, installable application is located at `bin/MyNdkApp-signed.apk`.

To install it on a connected device or emulator, run:
```bash
adb install -r bin/MyNdkApp-signed.apk
