package com.ejoy2dx.example;

import android.support.v4.app.FragmentActivity;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;
import android.os.Handler;
import android.os.Environment;
import android.view.Window;
import android.view.WindowManager;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.util.Log;

public class MainActivity extends FragmentActivity implements OnBackListener { 
    public GL2JNIView mView;
    protected FrameLayout mFrameLayout = null;
    
    public static String APK_PATH;
    public static String MEM_PATH;
    public static String SD_PATH;
        
    private boolean mShouldGameKillProcessExit = true; 
    public static Handler mHandler = new Handler();
    private boolean hasFocus = false;
    private boolean isResumeing = false;
    
    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        
        AndroidHelper.init(this);
        
        Window window = getWindow();
        //  int uiOptions = View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_FULLSCREEN;
        //  window.getDecorView().setSystemUiVisibility(uiOptions);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);

        setPaths();

        mView = new GL2JNIView(getApplication());

        ViewGroup.LayoutParams framelayout_params =
                new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT);

        mFrameLayout = new FrameLayout(this);
        mFrameLayout.setLayoutParams(framelayout_params);

        mFrameLayout.addView(mView);

        setContentView(mFrameLayout);
    }
    @Override
    protected void onDestroy(){
        super.onDestroy();

        mView.onExit();
        if(mView != null)
            mView = null;

        if (mShouldGameKillProcessExit) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    android.os.Process.killProcess(android.os.Process.myPid());
                }
            });
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        mView.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        isResumeing = true;
        resumeIfHasFocus();
    }
    
    private void resumeIfHasFocus() {
        if(hasFocus && isResumeing) {
            mView.onResume();
            isResumeing = false;
        }
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        this.hasFocus = hasFocus;
        resumeIfHasFocus();
        if (hasFocus) {
            mView.setSystemUiVisibility(
                    mView.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | mView.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | mView.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | mView.SYSTEM_UI_FLAG_HIDE_NAVIGATION // hide nav bar
                            | mView.SYSTEM_UI_FLAG_FULLSCREEN // hide status bar
                            | mView.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }   
    
    
    @Override
    protected void onStart() {
        super.onStart();
    }
    
    @Override
    protected void onStop() {
        super.onStop();
    }
    
    @Override
    public void onBackPress() {
        mView.onBackPress();
    }

    private void setPaths() {
        ApplicationInfo appInfo;
        PackageManager packMgmr = getApplication().getPackageManager();
        try {
            appInfo = packMgmr.getApplicationInfo(getApplication().getPackageName(), 0);
        } catch (NameNotFoundException e) {
            e.printStackTrace();
            throw new RuntimeException("Unable to locate assets, aborting...");
        }

        APK_PATH = appInfo.sourceDir;

        MEM_PATH =  getFilesDir().getPath();
        
        SD_PATH = "";
        if (Environment.getExternalStorageState().equals(android.os.Environment.MEDIA_MOUNTED)) {
            SD_PATH = Environment.getExternalStorageDirectory().getPath();
        }
    }
    
    public void runOnGLThread(final Runnable r) {
        this.mView.queueEvent(r);
    }
    
    public int getViewWidth() {
        return mView.getWidth();
    }
    
    public int getViewHeight() {
        return mView.getHeight();
    }
    
    public boolean isInit() {
        return mView != null && mView.isInit();
    }
    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
 //   public native String stringFromJNI();

    // Used to load the 'native-lib' library on application startup.
    static {
        System.loadLibrary("ejoy2dx-lib");
        System.loadLibrary("native-lib");
    }
}
