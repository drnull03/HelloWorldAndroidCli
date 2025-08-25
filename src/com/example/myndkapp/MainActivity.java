package com.example.myndkapp;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends Activity {

    // Load our native library. The name must match the library
    // we compiled.
    static {
        System.loadLibrary("native-lib");
    }

    // Declare the native method that is implemented in C++
    public native int addNumbers(int a, int b);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // --- THIS IS THE FIX ---
        // Use the generated R.id constant directly to find the TextView.
        // This is safer and more efficient.
        TextView resultTextView = findViewById(R.id.result_textview);

        // Call the native C++ function
        int result = addNumbers(5, 7);

        // Display the result
        resultTextView.setText("5 + 7 = " + result);
    }
}
