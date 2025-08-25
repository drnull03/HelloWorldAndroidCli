#!/bin/bash

# --- build.sh ---
# A script to manually compile, package, and sign an Android NDK application
# without using Gradle. This version includes the required C++ shared library.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# This script relies on the following environment variables being set:
# - ANDROID_HOME: Path to the Android SDK
# - ANDROID_NDK_HOME: Path to the Android NDK
# - PLATFORM: Path to a specific Android platform version
# - BUILD_TOOLS: Path to a specific build-tools version

# --- Initial Setup ---
echo "--- 1. Cleaning up previous build artifacts ---"
rm -rf obj libs bin build
mkdir -p libs/arm64-v8a obj bin build

# --- Step 1: Compile Native Code (NDK) ---
echo "--- 2. Compiling C++ Native Code ---"
$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++ \
    -shared \
    -o libs/arm64-v8a/libnative-lib.so \
    jni/native-lib.cpp

# --- Step 2: Compile Resources (AAPT2) ---
echo "--- 3. Compiling Resources ---"
$BUILD_TOOLS/aapt2 compile --dir res -o bin/compiled_res.zip

# --- Step 3: Link Resources & Generate R.java (AAPT2) ---
echo "--- 4. Linking Resources and Generating R.java ---"
$BUILD_TOOLS/aapt2 link \
    -o bin/base.apk \
    --manifest AndroidManifest.xml \
    -I "$PLATFORM/android.jar" \
    --java src \
    bin/compiled_res.zip

# --- Step 4: Compile Java Sources (javac) ---
echo "--- 5. Compiling Java Sources ---"
javac -d obj \
    -classpath "$PLATFORM/android.jar" \
    src/com/example/myndkapp/*.java

# --- Step 5: Convert to DEX format (d8) ---
echo "--- 6. Converting .class files to DEX format ---"
$BUILD_TOOLS/d8 obj/com/example/myndkapp/*.class \
    --output bin \
    --lib "$PLATFORM/android.jar"

# --- Step 6: Package the APK ---
echo "--- 7. Packaging the APK ---"
# Start with the resource-only APK
cp bin/base.apk bin/unaligned_app.apk
# Add the compiled Java code
zip -uj bin/unaligned_app.apk bin/classes.dex

# Create the temporary structure for native libraries
mkdir -p build/lib/arm64-v8a

# Copy our own native library
cp libs/arm64-v8a/libnative-lib.so build/lib/arm64-v8a/

# --- THIS IS THE FIX ---
# Find and copy the C++ shared library dependency from the NDK
LIBCXX_PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"
cp "$LIBCXX_PATH" build/lib/arm64-v8a/

# Add all libraries from the temporary structure to the APK
(cd build && zip -r ../bin/unaligned_app.apk lib)

# --- Step 7: Align the APK (zipalign) ---
echo "--- 8. Aligning the APK ---"
$BUILD_TOOLS/zipalign -v 4 bin/unaligned_app.apk bin/MyNdkApp-final.apk

# --- Step 8: Sign the APK (apksigner) ---
echo "--- 9. Signing the APK ---"
$BUILD_TOOLS/apksigner sign \
    --ks debug.keystore \
    --ks-pass pass:android \
    --out bin/MyNdkApp-signed.apk \
    bin/MyNdkApp-final.apk

# --- Final Message ---
echo ""
echo "--- Build successful! ---"
echo "Final APK created at: bin/MyNdkApp-signed.apk"
echo "To install, run: adb install -r bin/MyNdkApp-signed.apk"
