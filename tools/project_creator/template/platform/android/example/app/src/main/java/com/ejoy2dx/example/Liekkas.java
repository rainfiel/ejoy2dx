package com.ejoy2dx.example;

import android.content.res.AssetManager;

public class Liekkas {
    // for engine
    public static native boolean engineInit(AssetManager mgr);
    public static native void engineDestory();
    public static native void enginePause();
    public static native void engineResume();
    
    // static {
    //     System.loadLibrary("Liekkas");
    // }
}       