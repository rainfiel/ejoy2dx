package com.ejoy2dx.example;

import android.content.Context;
import android.content.res.AssetManager;

public class JniProxy {

	public static native void nativeSetContext(final Context pContext, final AssetManager pAssetManager);

	public static native void nativeTouchesBegin(int id, float x, float y);
	public static native void nativeTouchesEnd(int id, float x, float y, float vx, float vy);
	public static native void nativeTouchesMove(int[] id, float[] x, float[] y, float vx, float vy);
	public static native void nativeTouchesCancel(int[] ids, float[] xs, float[] ys);
	
	public static native void nativeInit(String apkString, String memString, String sdString,String userId);
	public static native void nativeExit();
	public static native void nativeResize(int w, int h);
	public static native void nativeRender(float during);
	public static native void nativeReload();
	
	public static native void nativeOnPause();
	public static native void nativeOnResume();

	public static native void nativeMessage(int id, byte[] data);
	public static native void nativeMessageNull(int id);
	
	public static native void nativeOnHttpPostBinaryRet(int cbid, int statusCode, String ret);
	public static native void nativeOnHttpSuccess(int cbid, String response);
	public static native void nativeOnHttpFail(int cbid, String url);
	public static native void nativeOnHttpProgress(int cbid, float progress);

	public static native void nativeOnFriendListLoad(int type, String errmsg);
	public static native void nativeOtherUserInfo(int cbid, String msg, int success);
	
	public static native void nativeOnNearbyPlayersLoad(int cbid, String errmsg);
	
	// 3rd sdk
	public static native void nativeOnLoginSuccess(String name, String token, String ud);
	public static native void nativeOnLoginFail(int ignore, int errcoce, String errmsg);
	public static native void nativeOnLogout();
	public static native void nativeOnRankListSuccess(int type);
	public static native void nativeOnRankListFail(int type);
	public static native void nativeOnBuySuccess(String number, String sign);
	public static native void nativeOnBuyFail(String msg);
	
	// location
	public static native void nativeOnLocationSuccess(double latitude, double lontitude);
	public static native void nativeOnLocationFail(String errmsg);
	
	// push
	public static native void nativeOnRegisterDevice(String token, String lang);
	
	public static native void nativeOnBackPress();
	public static native void nativeOnBindQuickLogin(int succeed);
	
	public static native void nativeSetEditTextDialogResult(int sid, byte[] pBytes);
	
	public static native void nativeExecuteVideoCallback(int index,int event);

	public static native void nativeHandleOpenUrl(String url);

	public static native void nativeOnShareResult(int ret);
	
	// ejoysdk
	public static native long nativeGetLuaState();

	//momo video
	public static native void nativeOnMomoVideoSuccess(String url);
	public static native void nativeOnMomoVideoFail(String err);
}
