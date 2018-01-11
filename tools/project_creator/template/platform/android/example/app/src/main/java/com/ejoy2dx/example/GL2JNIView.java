package com.ejoy2dx.example;


import java.io.UnsupportedEncodingException;

import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;
import javax.microedition.khronos.opengles.GL10;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.PixelFormat;
import android.opengl.GLSurfaceView;
import android.util.Log;
import android.view.MotionEvent;
import android.view.VelocityTracker;

public class GL2JNIView extends GLSurfaceView {
    private static String TAG = "GL2JNIView";
    
    private Renderer mRenderer;
    private String mOpenUrlAfterInit = null;
    private VelocityTracker mVelocityTracker = null;
    private float vx, vy;

    public GL2JNIView(Context context) {
        super(context);
        init(false, 0, 0);
    }

    public GL2JNIView(Context context, boolean translucent, int depth, int stencil) {
        super(context);
        init(translucent, depth, stencil);
    }
    
    public boolean isInit() {
    	return mRenderer != null;
    }

    private void init(boolean translucent, int depth, int stencil) {

        /* By default, GLSurfaceView() creates a RGB_565 opaque surface.
         * If we want a translucent one, we should change the surface's
         * format here, using PixelFormat.TRANSLUCENT for GL Surfaces
         * is interpreted as any 32-bit surface with alpha by SurfaceFlinger.
         */
        if (translucent) {
            this.getHolder().setFormat(PixelFormat.TRANSLUCENT);
        }

        /* Setup the context factory for 2.0 rendering.
         * See ContextFactory class definition below
         */
        setEGLContextFactory(new ContextFactory());

        /* We need to choose an EGLConfig that matches the format of
         * our surface exactly. This is going to be done in our
         * custom config chooser. See ConfigChooser class definition
         * below.
         */
        setEGLConfigChooser( translucent ?
                             new ConfigChooser(8, 8, 8, 8, depth, stencil) :
                             new ConfigChooser(5, 6, 5, 0, depth, stencil) );

        /* Set the renderer responsible for frame rendering */
        mRenderer = new Renderer();
        setRenderer(mRenderer);
        
        Log.w(TAG, "GL2JNIView inited");
        vx = vy = 0.0f;
    }

    private static class ContextFactory implements GLSurfaceView.EGLContextFactory {
        private static int EGL_CONTEXT_CLIENT_VERSION = 0x3098;
        public EGLContext createContext(EGL10 egl, EGLDisplay display, EGLConfig eglConfig) {
            Log.w(TAG, "creating OpenGL ES 2.0 context");
            checkEglError("Before eglCreateContext", egl);
            int[] attrib_list = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL10.EGL_NONE };
            EGLContext context = egl.eglCreateContext(display, eglConfig, EGL10.EGL_NO_CONTEXT, attrib_list);
            checkEglError("After eglCreateContext", egl);
            return context;
        }

        public void destroyContext(EGL10 egl, EGLDisplay display, EGLContext context) {
            egl.eglDestroyContext(display, context);
        }
    }

    @Override
    public void onPause(){
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleOnPause();
            }
        });
        this.setRenderMode(RENDERMODE_WHEN_DIRTY);
    }
    
    @Override
    public void onResume(){
    	super.onResume();
        this.setRenderMode(RENDERMODE_CONTINUOUSLY);
    	mRenderer.reset_time();
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleOnResume();
            }
        });
    }
    
    public void onExit() {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleExit();
            }
        });
    }

	public void onMessage(final int id, final byte[] data) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleMessage(id, data);
            }
        });
    }
    
    public void onMessageNull(final int id) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleMessageNull(id);
            }
        });
    }
    
    public void onHttpPostBinaryRet(final int cbid, final int statusCode, final String ret) {
    	queueEvent(new Runnable() {
			@Override
			public void run() {
				mRenderer.handleHttpPostBinaryRet(cbid, statusCode, ret);
			}
		});
    }
    
    public void onHttpSuccess(final int cbid, final String response) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleHttpSuccess(cbid, response);
            }
        });
    }    
    
    public void onHttpFail(final int cbid, final String url) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleHttpFail(cbid, url);
            }
        });
    }   
    
    public void onHttpProgress(final int cbid, final float progress) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleHttpProgress(cbid, progress);
            }
        });
    } 
    public void onLoginSuccess(final String name, final String token, final String ud) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleLoginSuccess(name, token, ud);
            }
        });
    }
    
    public void onLoginFail(final int ignore, final int errcoce, final String errmsg) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleLoginFail(ignore, errcoce, errmsg);
            }
        });
    }
    
    public void onFriendListLoad(final int cbid, final String errmsg) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleFriendListLoad(cbid, errmsg);
            }
        });
    }
    
    public void onNearbyPlayersLoad(final int cbid, final String errmsg) {
    	queueEvent(new Runnable() {
			@Override
			public void run() {
				mRenderer.handleNearbyPlayersLoad(cbid, errmsg);
			}
		});
    }
    
    public void onRankListSuccess(final int type) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleRankListSuccess(type);
            }
        });
    }
    
    public void onRankListFail(final int type) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleRankListFail(type);
            }
        });
    }

    public void onOtherUserInfoSuccess(final int cbid) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleOtherUserInfoSuccess(cbid);
            }
        });
    }
    
    public void onOtherUserInfoFail(final int cbid, final String reason) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleOtherUserInfoFail(cbid, reason);
            }
        });
    }
    
    public void onBuySuccess(final String number, final String sign) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleBuySuccess(number, sign);
            }
        });
    }
    
    public void onBuyFail(final String msg) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleBuyFail(msg);
            }
        });
    }
    
    public void onLocationSuccess(final double lat, final double lon) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleLocationSuccess(lat, lon);
            }
        });
    }    
    
    public void onLocationFail(final String errmsg) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleLocationFail(errmsg);
            }
        });
    }    
    
    public void onRegisterDevice(final String token, final String lang) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleRegisterDevice(token, lang);
            }
        });
    }    
    public void onBindQuickLogin(final int succeed) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.onBindQuickLogin(succeed);
            }
        });
    }
    
    public void onBackPress() {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleOnBackPress();
            }
        });
    }

    public void onShareResult(final int succeed) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleOnShareResult(succeed);
            }
        });
    }
    
    public void onSetOpenUrl(final String url) {
    	queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleSetOpenUrl(url);
            }
        });
    }
    
    public void onEditTextDialogResult(final int cbid, final String result) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleEditTextDialogResult(cbid, result);
            }
        });
    }
    
    public void onReload() {
    	queueEvent(new Runnable() {
    		@Override
    		public void run() {
    			mRenderer.handleReload();
    		}
    	});
    }
    
    public void onLogout() {
    	queueEvent(new Runnable() {
    		@Override
    		public void run() {
    			mRenderer.handleLogout();
    		}
    	});
    }

    public void onPreferFrame(final int frame) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handlePreferFrame(frame);
            }
        });
    }

    //momo video
    public void onMomoVideoSuccess(final String url) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleMomoVideoSuccess(url);
            }
        });
    }

    public void onMomoVideoFail(final String err) {
        queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.handleMomoVideoFail(err);
            }
        });        
    }
    
    @SuppressLint("ClickableViewAccessibility")
	public boolean onTouchEvent(final MotionEvent event) {
        // these data are used in ACTION_MOVE and ACTION_CANCEL
        final int pointerNumber = event.getPointerCount();
        final int[] ids = new int[pointerNumber];
        final float[] xs = new float[pointerNumber];
        final float[] ys = new float[pointerNumber];

        for (int i = 0; i < pointerNumber; i++) {
            ids[i] = event.getPointerId(i);
            xs[i] = event.getX(i);
            ys[i] = event.getY(i);
        }
        
        switch (event.getAction() & MotionEvent.ACTION_MASK) {
        case MotionEvent.ACTION_POINTER_DOWN:
            @SuppressWarnings("deprecation")
            final int indexPointerDown = event.getAction() >> MotionEvent.ACTION_POINTER_ID_SHIFT;
            final int idPointerDown = event.getPointerId(indexPointerDown);
            final float xPointerDown = event.getX(indexPointerDown);
            final float yPointerDown = event.getY(indexPointerDown);

            addVelocityMovement(event);

            queueEvent(new Runnable() {
                @Override
                public void run() {
                    mRenderer.handleActionDown(idPointerDown, xPointerDown, yPointerDown);
                }
            });
            break;
            
        case MotionEvent.ACTION_DOWN:
            // there are only one finger on the screen
            final int idDown = event.getPointerId(0);
            final float xDown = xs[0];
            final float yDown = ys[0];

            obtainVelocityTracker();
            addVelocityMovement(event);
            
            queueEvent(new Runnable() {
                @Override
                public void run() {
                    mRenderer.handleActionDown(idDown, xDown, yDown);
                }
            });
            break;

        case MotionEvent.ACTION_MOVE:
            addVelocityMovement(event);
        	computeVelocity();
            queueEvent(new Runnable() {
                @Override
                public void run() {
                    mRenderer.handleActionMove(ids, xs, ys, vx, vy);
                }
            });
            break;

        case MotionEvent.ACTION_POINTER_UP:
            @SuppressWarnings("deprecation")
            final int indexPointUp = event.getAction() >> MotionEvent.ACTION_POINTER_ID_SHIFT;
            final int idPointerUp = event.getPointerId(indexPointUp);
            final float xPointerUp = event.getX(indexPointUp);
            final float yPointerUp = event.getY(indexPointUp);
            addVelocityMovement(event);
            computeVelocity();
            
            queueEvent(new Runnable() {
                @Override
                public void run() {
                    mRenderer.handleActionUp(idPointerUp, xPointerUp, yPointerUp, vx, vy);
                }
            });
            break;
            
        case MotionEvent.ACTION_UP:  
            // there are only one finger on the screen
            final int idUp = event.getPointerId(0);
            final float xUp = xs[0];
            final float yUp = ys[0];
            addVelocityMovement(event);
            computeVelocity();
            releaseVelocityTracker();
            
            queueEvent(new Runnable() {
                @Override
                public void run() {
                    mRenderer.handleActionUp(idUp, xUp, yUp, vx, vy);
                }
            });
            break;

        case MotionEvent.ACTION_CANCEL:
            releaseVelocityTracker();
            queueEvent(new Runnable() {
            	@Override
            	public void run() {
            		mRenderer.handleActionCancel(ids, xs, ys);
            	}
            });
            break;
        }
      
        return true;
    }

    private void addVelocityMovement(final MotionEvent event) {
        if (mVelocityTracker != null) {
            mVelocityTracker.addMovement(event);
        }
    }

    private void obtainVelocityTracker() {
        if (mVelocityTracker == null) {
            mVelocityTracker = VelocityTracker.obtain();
        } else {
            mVelocityTracker.clear();
        }
    }

    private void releaseVelocityTracker() {
        if (mVelocityTracker != null) {
            mVelocityTracker.clear();
            mVelocityTracker.recycle();
            mVelocityTracker = null;
        }
    }
    
    private void computeVelocity() {
        mVelocityTracker.computeCurrentVelocity(1000);
        vx = mVelocityTracker.getXVelocity();
        vy = mVelocityTracker.getYVelocity();
    }

    private static void checkEglError(String prompt, EGL10 egl) {
        int error;
        while ((error = egl.eglGetError()) != EGL10.EGL_SUCCESS) {
            Log.e(TAG, String.format("%s: EGL error: 0x%x", prompt, error));
        }
    }

    private static class ConfigChooser implements GLSurfaceView.EGLConfigChooser {

        public ConfigChooser(int r, int g, int b, int a, int depth, int stencil) {
            mRedSize = r;
            mGreenSize = g;
            mBlueSize = b;
            mAlphaSize = a;
            mDepthSize = depth;
            mStencilSize = stencil;
        }

        /* This EGL config specification is used to specify 2.0 rendering.
         * We use a minimum size of 4 bits for red/green/blue, but will
         * perform actual matching in chooseConfig() below.
         */
        private static int EGL_OPENGL_ES2_BIT = 4;
        private static int[] s_configAttribs2 =
        {
            EGL10.EGL_RED_SIZE, 4,
            EGL10.EGL_GREEN_SIZE, 4,
            EGL10.EGL_BLUE_SIZE, 4,
            EGL10.EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
            EGL10.EGL_NONE
        };

        public EGLConfig chooseConfig(EGL10 egl, EGLDisplay display) {

            /* Get the number of minimally matching EGL configurations
             */
            int[] num_config = new int[1];
            egl.eglChooseConfig(display, s_configAttribs2, null, 0, num_config);

            int numConfigs = num_config[0];

            if (numConfigs <= 0) {
                throw new IllegalArgumentException("No configs match configSpec");
            }

            /* Allocate then read the array of minimally matching EGL configs
             */
            EGLConfig[] configs = new EGLConfig[numConfigs];
            egl.eglChooseConfig(display, s_configAttribs2, configs, numConfigs, num_config);

            /* Now return the "best" one
             */
            return chooseConfig(egl, display, configs);
        }

        public EGLConfig chooseConfig(EGL10 egl, EGLDisplay display,
                EGLConfig[] configs) {
            for(EGLConfig config : configs) {
                int d = findConfigAttrib(egl, display, config,
                        EGL10.EGL_DEPTH_SIZE, 0);
                int s = findConfigAttrib(egl, display, config,
                        EGL10.EGL_STENCIL_SIZE, 0);

                // We need at least mDepthSize and mStencilSize bits
                if (d < mDepthSize || s < mStencilSize)
                    continue;

                // We want an *exact* match for red/green/blue/alpha
                int r = findConfigAttrib(egl, display, config,
                        EGL10.EGL_RED_SIZE, 0);
                int g = findConfigAttrib(egl, display, config,
                            EGL10.EGL_GREEN_SIZE, 0);
                int b = findConfigAttrib(egl, display, config,
                            EGL10.EGL_BLUE_SIZE, 0);
                int a = findConfigAttrib(egl, display, config,
                        EGL10.EGL_ALPHA_SIZE, 0);

                if (r == mRedSize && g == mGreenSize && b == mBlueSize && a == mAlphaSize)
                    return config;
            }
            return null;
        }

        private int findConfigAttrib(EGL10 egl, EGLDisplay display,
                EGLConfig config, int attribute, int defaultValue) {

            if (egl.eglGetConfigAttrib(display, config, attribute, mValue)) {
                return mValue[0];
            }
            return defaultValue;
        }

        // Subclasses can adjust these values:
        protected int mRedSize;
        protected int mGreenSize;
        protected int mBlueSize;
        protected int mAlphaSize;
        protected int mDepthSize;
        protected int mStencilSize;
        private int[] mValue = new int[1];
    }


    private class Renderer implements GLSurfaceView.Renderer {
        private final static long NANOSECONDSPERMICROSECOND = 1000000L;
        private final static long NANOSECONDSPERSECOND = 1000000000L;

        private long last;
        private boolean need_reset = false;
        private boolean need_reload = false;
        private int prefer_frame = 30;
        private long STEP = (long)(1.0f / prefer_frame * NANOSECONDSPERSECOND);
       
        public void onDrawFrame(GL10 gl) {
        	if (need_reset)
        		reset_time();
        	
        	if (need_reload) {
        		JniProxy.nativeReload();
        		need_reload = false;
        		return ;
        	}
        	
        	long now = System.nanoTime();
        	long interval = now - last;
        	if (interval < STEP) {
        		try {
        			Thread.sleep((STEP - interval) / NANOSECONDSPERMICROSECOND);
        		} catch (Exception e) {}
        	}
        	
        	now = System.nanoTime();
        	interval = now - last;
        	last = now;
        	JniProxy.nativeRender((float)interval / NANOSECONDSPERSECOND);
        }
        
        public void reset_time(){
        	// last = System.currentTimeMillis();
        	last = System.nanoTime();
        	need_reset = false;
        }

        public void onSurfaceChanged(GL10 gl, int width, int height) {
            Log.w(TAG, "onSurfaceChanged");
            JniProxy.nativeResize(width, height);
        }

        public void onSurfaceCreated(GL10 gl, EGLConfig config) { 
            Log.w(TAG, "onSurfaceCreated");
            JniProxy.nativeInit(MainActivity.APK_PATH, MainActivity.MEM_PATH, MainActivity.SD_PATH,AndroidHelper.getUserID());
            reset_time();
        }
        
        public void handleActionDown(int id, float x, float y) {
            JniProxy.nativeTouchesBegin(id, x, y);
        }
        
        public void handleActionUp(int id, float x, float y, float vx, float vy) {
            JniProxy.nativeTouchesEnd(id, x, y, vx, vy);
        }
        
        public void handleActionCancel(final int[] ids, final float[] xs, final float[] ys) {
        	JniProxy.nativeTouchesCancel(ids, xs, ys);
        }
        
        public void handleActionMove(int[] id, float[] x, float[] y, float vx, float vy) {
            JniProxy.nativeTouchesMove(id, x, y, vx, vy);
        }
        
        public void handleOnPause() {
        	need_reset = true;
            JniProxy.nativeOnPause();
        }
        
        public void handleOnResume() {
        	reset_time();
            JniProxy.nativeOnResume();
        }
        
        public void handleExit() {
            JniProxy.nativeExit();
        }

        public void handleMessage(int id, byte[] data) {
            JniProxy.nativeMessage(id, data);
        }
        
        public void handleMessageNull(int id) {
            JniProxy.nativeMessageNull(id);
        }     
        
        public void handleHttpPostBinaryRet(int cbid, int statusCode, String ret) {
        	JniProxy.nativeOnHttpPostBinaryRet(cbid, statusCode, ret);
        }
        
        public void handleHttpSuccess(int cbid, String response) {
            JniProxy.nativeOnHttpSuccess(cbid, response);
        }
        
        public void handleHttpFail(int cbid, String url) {
            JniProxy.nativeOnHttpFail(cbid, url);
        }
        
        public void handleHttpProgress(int cbid, float progress) {
            JniProxy.nativeOnHttpProgress(cbid, progress);
        }
        public void handleLoginSuccess(String name, String token, String ud) {
            JniProxy.nativeOnLoginSuccess(name, token, ud);
        }
        
        public void handleLoginFail(int ignore, int errcoce, String errmsg) {
            JniProxy.nativeOnLoginFail(ignore, errcoce, errmsg);
        }        
        
        public void handleFriendListLoad(int cbid, String errmsg) {
            JniProxy.nativeOnFriendListLoad(cbid, errmsg);
        }
        
        public void handleNearbyPlayersLoad(int cbid, String errmsg) {
        	JniProxy.nativeOnNearbyPlayersLoad(cbid, errmsg);
        }
        
        public void handleRankListSuccess(int type) {
            JniProxy.nativeOnRankListSuccess(type);
        }
        
        public void handleRankListFail(int type) {
            JniProxy.nativeOnRankListFail(type);
        }

        public void handleOtherUserInfoSuccess(int cbid) {
           JniProxy.nativeOtherUserInfo(cbid, null, 1);
        }
        
        public void handleOtherUserInfoFail(int cbid, String reason) {
            JniProxy.nativeOtherUserInfo(cbid, reason, 0);
        }
        
        public void handleBuySuccess(String number, String sign) {
            JniProxy.nativeOnBuySuccess(number, sign);
        }
        
        public void handleBuyFail(String msg) {
            JniProxy.nativeOnBuyFail(msg);
        }
        
        public void handleLocationSuccess(double lat, double lon) {
            JniProxy.nativeOnLocationSuccess(lat, lon);
        }
        
        public void handleLocationFail(String errmsg) {
            JniProxy.nativeOnLocationFail(errmsg);
        }
        
        public void handleRegisterDevice(String token, String lang) {
            JniProxy.nativeOnRegisterDevice(token, lang);
        }        
        
        public void handleOnBackPress() {
            JniProxy.nativeOnBackPress();
        }

        public void handleOnShareResult(int succeed) {
            JniProxy.nativeOnShareResult(succeed);
        }
        
        public void handleSetOpenUrl(String url) {
        	mOpenUrlAfterInit = url;
        }
        
        public void onBindQuickLogin(int succeed){
            JniProxy.nativeOnBindQuickLogin(succeed);
        }
        
        public void handleEditTextDialogResult(final int sid, final String pResult){
			try {
				byte[] bytesUTF8 = pResult.getBytes("UTF8");
				JniProxy.nativeSetEditTextDialogResult(sid, bytesUTF8);
			} catch (UnsupportedEncodingException e) {
				e.printStackTrace();
			}
        }

        public void handleReload() {
        	need_reload = true;
        }
        
        public void handleLogout() {
        	JniProxy.nativeOnLogout();
        }

        public void handlePreferFrame(int frame) {
            prefer_frame = frame;
            STEP = (long)(1.0f / prefer_frame * NANOSECONDSPERSECOND);
        }

        //momo video
        public void handleMomoVideoSuccess(String url) {
            JniProxy.nativeOnMomoVideoSuccess(url);
        }
        public void handleMomoVideoFail(String err) {
            JniProxy.nativeOnMomoVideoFail(err);
        }
      }
}
