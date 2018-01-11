package com.ejoy2dx.example;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.IntBuffer;
import java.util.Enumeration;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.opengles.GL10;

import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.text.ClipboardManager;
import android.util.Log;


public class AndroidHelper {

	private static DeviceInfo sDeviceInfo;
	private static FileSystem sFileSystem;
	private static ImageSystem sImageSystem;
	protected static AssetManager sAssetManager;

	public static Context mContext;

	public static void init(final Context pContext) {
		AndroidHelper.sDeviceInfo = new DeviceInfo(pContext);
		AndroidHelper.sFileSystem = new FileSystem(pContext);
		AndroidHelper.sImageSystem = new ImageSystem(pContext);
		AndroidHelper.sAssetManager = pContext.getAssets();
		JniProxy.nativeSetContext(pContext, AndroidHelper.sAssetManager);
		mContext = pContext;

		Liekkas.engineInit(AndroidHelper.sAssetManager);
	}

	public static void finishActivity() {
		Activity activity = (Activity) mContext;
		activity.runOnUiThread(new Runnable() {
			public void run() {
				Activity activity = (Activity) mContext;
				activity.finish();
			}
		});
	}

	public static void terminateProcess() {
		Activity activity = (Activity) mContext;
		activity.runOnUiThread(new Runnable() {
			public void run() {
				android.os.Process.killProcess(android.os.Process.myPid());
			}
		});
	}

	public static Context getContext() {
		return mContext;
	}

	public static String getDeviceID() {
		return AndroidHelper.sDeviceInfo.getDeviceID();
	}

	public static ImageData getTextImage(byte[] text, int size, int color) {
		return AndroidHelper.sImageSystem.drawTextToBitmap(text, size, color);
	}

	public static String getDeviceNetworkType() {
		return AndroidHelper.sDeviceInfo.getDeviceNetworkType();
	}

	public static String getSystemVersion() {
		return Integer.toString(Build.VERSION.SDK_INT);
	}

	public static String getMetaData(String key) {
		if (mContext == null) {
			return null;
		}

		PackageManager pkgMgr = mContext.getPackageManager();
		if (pkgMgr == null) {
			return null;
		}

		String pkgName = mContext.getPackageName();
		try {
			ApplicationInfo appInfo = pkgMgr.getApplicationInfo(pkgName,
					PackageManager.GET_META_DATA);
			Bundle metaData = appInfo.metaData;
			if (metaData == null) {
				return null;
			}
			return metaData.getString(key);
		} catch (NameNotFoundException e) {
			return null;
		}
	}

	public static String getUserID() {
		String market = getMetaData("market");
		if (market == null) {
			market = "?";
		}
		String idstr = "Android" + "|" + Build.MODEL + "|"
				+ Build.VERSION.SDK_INT + "|"
				+ AndroidHelper.sDeviceInfo.getDeviceID() + "|" + market;
		// Log.e("user id:", idstr );
		return idstr.replace(' ', '_');
	}

	@SuppressWarnings("deprecation")
	public static void pasteBoardCopy(final String text) {
		Activity activity = (Activity) mContext;
		activity.runOnUiThread(new Runnable() {
			public void run() {
				ClipboardManager clipboard = (ClipboardManager) mContext
						.getSystemService(Context.CLIPBOARD_SERVICE);
				clipboard.setText(text);
			}
		});
	}

	public static void setPreferFrame(final int frame) {
		MainActivity activity = (MainActivity) mContext;
		activity.mView.onPreferFrame(frame);
	}

	public static double getTotalMemory() {
		return AndroidHelper.sDeviceInfo.getTotalMemory();
	}

	public static double getUsedMemory() {
		return AndroidHelper.sDeviceInfo.getUsedMemory();
	}

	public static int getDPI() {
		return AndroidHelper.sDeviceInfo.getDPI();
	}

	public static String getPreferredLanguage() {
		return AndroidHelper.sDeviceInfo.getPreferredLanguage();
	}

	public static boolean fileExists(String filename) {
		return AndroidHelper.sFileSystem.fileExists(filename);
	}

	public static byte[] readFile(String filename) {
		return AndroidHelper.sFileSystem.readFile(filename);
	}

	public static void writeFile(String filename, byte[] bytes) {
		AndroidHelper.sFileSystem.writeFile(filename, bytes);
	}

	public static void clearFile(String filename) {
		AndroidHelper.sFileSystem.clearFile(filename);
	}

	public static void mkdir(String path) {
		AndroidHelper.sFileSystem.mkdir(path);
	}

	public static void mkfiledir(String filename) {
		AndroidHelper.sFileSystem.createFileDirectory(filename);
	}

	public static String getPath(String path, String mode) {
		return AndroidHelper.sFileSystem.getPath(path, mode);
	}

	public static void saveToKeyChain(String service, String key, String val) {
		SharedPreferences s = mContext.getSharedPreferences(service,
				Context.MODE_PRIVATE);
		Editor edit = s.edit();
		edit.putString(key, val);
		edit.commit();
	}

	public static String getFromKeyChain(String service, String key) {
		SharedPreferences s = mContext.getSharedPreferences(service,
				Context.MODE_PRIVATE);
		String ret = s.getString(key, "");
		return ret;
	}

	public static void deleteKeyChain(String service) {
		SharedPreferences s = mContext.getSharedPreferences(service,
				Context.MODE_PRIVATE);
		s.edit().clear().commit();
	}

	public static String getDefaultLanguage() {
		Locale l = Locale.getDefault();
		String language = l.getLanguage();
		String country = l.getCountry();
		if (language.equals("zh")) {
			if (country.equals("CN")) {
				language = "zh_CN";
			}
		}
		return language;
	}

	public static byte[] getFileDataFromAssets(String pPath) {
		ByteArrayOutputStream output = null;
		InputStream fileStream = null;
		try {
			fileStream = mContext.getAssets().open(pPath);
			output = new ByteArrayOutputStream();
			byte[] buffer = new byte[4096];
			int n = 0;
			while (-1 != (n = fileStream.read(buffer))) {
				output.write(buffer, 0, n);
			}
			return output.toByteArray();

		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				if (fileStream != null) {
					fileStream.close();
				}
				if (output != null) {
					output.close();
				}
			} catch (IOException e) {
				e.printStackTrace();
			}

		}
		return null;
	}

	@SuppressWarnings("rawtypes")
	public static boolean unzipFile(String zipFileName, String outputDirectory) {
		ZipFile zipFile = null;
		try {
			zipFile = new ZipFile(zipFileName);
			Enumeration e = zipFile.entries();
			ZipEntry zipEntry = null;
			File dest = new File(outputDirectory);
			dest.mkdirs();
			while (e.hasMoreElements()) {
				zipEntry = (ZipEntry) e.nextElement();
				String entryName = zipEntry.getName();
				InputStream in = null;
				FileOutputStream out = null;
				try {
					if (zipEntry.isDirectory()) {
						String name = zipEntry.getName();
						name = name.substring(0, name.length() - 1);
						File f = new File(outputDirectory + File.separator
								+ name);
						f.mkdirs();
					} else {
						int index = entryName.lastIndexOf("\\");
						if (index != -1) {
							File df = new File(outputDirectory + File.separator
									+ entryName.substring(0, index));
							df.mkdirs();
						}
						index = entryName.lastIndexOf("/");
						if (index != -1) {
							File df = new File(outputDirectory + File.separator
									+ entryName.substring(0, index));
							df.mkdirs();
						}
						File f = new File(outputDirectory + File.separator
								+ zipEntry.getName());
						// f.createNewFile();
						in = zipFile.getInputStream(zipEntry);
						out = new FileOutputStream(f);
						int c;
						byte[] by = new byte[1024];
						while ((c = in.read(by)) != -1) {
							out.write(by, 0, c);
						}
						out.flush();
						return true;
					}
				} catch (Exception ex) {
					Log.e("ZIP", "Unzip exception inner", ex);
					ex.printStackTrace();
					return false;
				} finally {
					if (in != null) {
						try {
							in.close();
						} catch (IOException ex) {
						}
					}
					if (out != null) {
						try {
							out.close();
						} catch (IOException ex) {
						}
					}
				}
			}
		} catch (Exception ex) {
			Log.e("ZIP", "Unzip exception outter", ex);
			return false;
		} finally {
			if (zipFile != null) {
				try {
					zipFile.close();
				} catch (Exception ex) {
					Log.e("ZIP", "Unzip exception close", ex);
				}
			}
		}
		return false;
	}

	public static boolean screenShot(String filename, String thumbname,
			float scale) {
		MainActivity activity = (MainActivity) mContext;
		if (activity == null) {
			Log.e("screenShot", "screenShot activity == null");
			return false;
		}

		OutputStream fout = null;
		try {
			EGL10 egl = (EGL10) EGLContext.getEGL();
			GL10 gl = (GL10) egl.eglGetCurrentContext().getGL();
			int w = activity.mView.getWidth();
			int h = activity.mView.getHeight();
			// Log.e("screenShot", String.format("screenShot size %d %d %f", w,
			// h, scale));
			Bitmap bitmap = SavePixels(0, 0, w, h, gl);

			File thumbFile = new File(thumbname);
			fout = new FileOutputStream(thumbFile);
			Bitmap scaleBitmap = Bitmap.createScaledBitmap(bitmap, 150, 150 * h
					/ w, false);
			scaleBitmap.compress(Bitmap.CompressFormat.JPEG, 80, fout);
			fout.flush();
			fout.close();
			// Log.e("screenShot", String.format("screenShot thumbname %d %d " +
			// thumbname,
			// scaleBitmap.getWidth(), scaleBitmap.getHeight()));
			scaleBitmap.recycle();

			File imageFile = new File(filename);
			fout = new FileOutputStream(imageFile);
			if (scale < 1.0f && scale > 0) {
				// Log.e("screenShot",
				// String.format("screenShot scale size %d %d", Math.round(w *
				// scale), Math.round(h * scale)));
				Bitmap scaleBmp = Bitmap.createScaledBitmap(bitmap,
						Math.round(w * scale), Math.round(h * scale), false);
				scaleBmp.compress(Bitmap.CompressFormat.JPEG, 100, fout);
				scaleBmp.recycle();
			} else {
				// Log.e("screenShot",
				// String.format("screenShot normal size %d %d", w, h));
				bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fout);
			}
			bitmap.recycle();

			fout.flush();
			// Log.e("screenShot", "screenShot filename " + filename);

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				fout.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return true;
	}

	private static Bitmap SavePixels(int x, int y, int w, int h, GL10 gl) {
		int b[] = new int[w * (y + h)];
		int bt[] = new int[w * h];
		IntBuffer ib = IntBuffer.wrap(b);
		ib.position(0);
		gl.glReadPixels(x, 0, w, y + h, GL10.GL_RGBA, GL10.GL_UNSIGNED_BYTE, ib);

		for (int i = 0, k = 0; i < h; i++, k++) {
			// remember, that OpenGL bitmap is incompatible with Android bitmap
			// and so, some correction need.
			for (int j = 0; j < w; j++) {
				int pix = b[i * w + j];
				int pb = (pix >> 16) & 0xff;
				int pr = (pix << 16) & 0x00ff0000;
				int pix1 = (pix & 0xff00ff00) | pr | pb;
				bt[(h - k - 1) * w + j] = pix1;
			}
		}

		Bitmap sb = Bitmap.createBitmap(bt, w, h, Bitmap.Config.ARGB_8888);
		return sb;
	}

	public static String getBasePath(Context context) {
		String strPath = null;
		if (!android.os.Environment.getExternalStorageState().equals(
				android.os.Environment.MEDIA_MOUNTED)) {
			strPath = context.getApplicationContext().getFilesDir()
					+ "/Download/img.jpeg";
		} else
			strPath = Environment.getExternalStorageDirectory()
					+ "/Download/img.jpeg";

		return strPath;
	}

	public static void onExit() {
		android.os.Process.killProcess(android.os.Process.myPid());
	}
}
