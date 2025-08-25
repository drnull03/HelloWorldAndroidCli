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
