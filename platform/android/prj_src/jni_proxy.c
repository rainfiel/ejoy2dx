#include <string.h>
#include <assert.h>
#include <lua.h>
#include <math.h>
#include <time.h>
#include <stdbool.h>
#include <stdio.h>
#include <android/log.h>
#include <jni.h>

#include "opengl.h"
#include "framework/fw.h"
#include "screen.h"

#include "gesture.h"
#include "android_helper.h"

extern char _apkpath[255];
extern char _mempath[255];
extern char _sdpath[255];
static char g_user_id[512];

#define kTapMaxDurationBetweenTaps 0.2

static float CLOCK_TO_SECOND = 1.0f / CLOCKS_PER_SEC;
static clock_t last_tab_time = 0;

static bool is_recognizing = false; //
static int tabcount = 1;

#define  LOG_TAG    "jni_proxy"
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)

jint JNI_OnLoad(JavaVM *vm, void *reserved) {
	setJavaVM(vm);

	last_tab_time = clock();
	return JNI_VERSION_1_4;
}

void JNICALL Java_com_ejoy2dx_doorkickers_JniProxy_nativeSetContext(JNIEnv*  env, jobject thiz, jobject context, jobject assetManager) {
	setassetmanager(AAssetManager_fromJava(env, assetManager));
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeTouchesBegin(JNIEnv * env, jclass class,
	jint id, jfloat x, jfloat y) {

	clock_t cur_time = clock();
	clock_t dt = (cur_time - last_tab_time) * CLOCK_TO_SECOND;
	if (dt < kTapMaxDurationBetweenTaps) {
		tabcount++;
	} else {
		tabcount = 1;
		last_tab_time = cur_time;
	}

	LOGI("TOUCH_BEGIN:%d", id);

	int disable_gesture = ejoy2d_fw_touch(x, y, TOUCH_BEGIN, id);
	if (!disable_gesture) {
		gr_touch_begin(id, x, y);
		is_recognizing = true;
	}
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeTouchesEnd(JNIEnv * env, jclass class,
	jint id, jfloat x, jfloat y, jfloat vx, jfloat vy) {

	LOGI("TOUCH_END:%d", id);

	int disable_gesture = ejoy2d_fw_touch(x, y, TOUCH_END, id);
	if (disable_gesture && is_recognizing) {
		gr_touch_cancel(0, NULL, NULL, NULL);
	} else if (is_recognizing) {
		gr_touch_end(id, x, y, vx, vy);
	}

	is_recognizing = false;
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeTouchesMove(JNIEnv* env, jclass class,
		jintArray ids, jfloatArray xs, jfloatArray ys, jfloat vx, jfloat vy) {
	int size = (*env)->GetArrayLength(env, ids);
	jint _ids[size];
	jfloat _xs[size];
	jfloat _ys[size];

	(*env)->GetIntArrayRegion(env, ids, 0, size, _ids);
	(*env)->GetFloatArrayRegion(env, xs, 0, size, _xs);
	(*env)->GetFloatArrayRegion(env, ys, 0, size, _ys);

	int i=0;
	int disable_gesture=0;
  for (i=0; i<size; i++) {
		if (ejoy2d_fw_touch(_xs[i], _ys[i], TOUCH_MOVE, _ids[i]))
			disable_gesture = 1;
	}

	if (disable_gesture && is_recognizing) {
		gr_touch_cancel(0, NULL, NULL, NULL);
		is_recognizing = false;
	} else if (is_recognizing) {
		gr_touch_move(size, _ids, _xs, _ys, vx, vy);
	}
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeTouchesCancel(JNIEnv* env, jclass class, jintArray ids, jfloatArray xs, jfloatArray ys) {
    int size = (*env)->GetArrayLength(env, ids);
    jint id[size];
    jfloat x[size];
    jfloat y[size];

    (*env)->GetIntArrayRegion(env, ids, 0, size, id);
    (*env)->GetFloatArrayRegion(env, xs, 0, size, x);
    (*env)->GetFloatArrayRegion(env, ys, 0, size, y);

    float _x = 0, _y = 0;
    if (size > 0) {
        _x = x[0];
        _y = y[0];
    }

    ejoy2d_fw_touch(_x, _y, TOUCH_CANCEL, tabcount);
    gr_touch_cancel(0, NULL, NULL, NULL);
    is_recognizing = false;
}

static bool inited = false;
void Java_com_ejoy2dx_doorkickers_JniProxy_nativeInit(JNIEnv * env, jclass class,
		jstring apkPath, jstring memPath, jstring sdPath, jstring userID) {
	const char* apk = (*env)->GetStringUTFChars(env, apkPath, NULL);
	const char* mem = (*env)->GetStringUTFChars(env, memPath, NULL);
	const char* sd = (*env)->GetStringUTFChars(env, sdPath, NULL);
	const char* id = (*env)->GetStringUTFChars(env, userID, NULL);
	strcpy(_apkpath, apk);
	strcpy(_mempath, mem);
	strcpy(_sdpath, sd);
	strcpy(g_user_id, id);
	(*env)->ReleaseStringUTFChars(env, apkPath, apk);
	(*env)->ReleaseStringUTFChars(env, memPath, mem);
	(*env)->ReleaseStringUTFChars(env, sdPath, sd);
	(*env)->ReleaseStringUTFChars(env, userID, id);
	inited = true;

	struct STARTUP_INFO* startup = (struct STARTUP_INFO*)malloc(sizeof(struct STARTUP_INFO));
	startup->folder = "";
	startup->lua_root = NULL;
	startup->script = NULL;
	startup->user_data = NULL;

	startup->orix = 0;
	startup->oriy = 0;
	startup->width = 800;
	startup->height = 600;
	startup->scale = 1.0;
	startup->reload_count = 0;
	startup->serialized = NULL;
	startup->auto_rotate = true;

	ejoy2d_fw_init(startup);
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeExit(JNIEnv * env, jclass class) {
	gr_release();
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeReload(JNIEnv * env, jclass class) {
	// ejoy2d_reload();
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeResize(JNIEnv * env, jclass class, jint w, jint h) {
	if (inited) {
		LOGI("screen size:(%d, %d)\n", w, h);
		ejoy2d_fw_view_layout(1, 0, 0, w, h);
		screen_init(w, h, 1);
	}
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeRender(JNIEnv * env, jclass class, float during) {
	if (during > 1) {
		during = 0.033f;
	}
	ejoy2d_fw_update(during);
	ejoy2d_fw_frame();
	gr_touch_update();
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeOnPause(JNIEnv * env, jclass class) {
	ejoy2d_fw_pause();
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeOnResume(JNIEnv * env, jclass class) {
	ejoy2d_fw_resume();
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeMessage(JNIEnv* env, jclass class,
		jint id, jbyteArray data) {
	if (id > 0) {
		jbyte* byteArray = (*env)->GetByteArrayElements(env, data, false);
		ejoy2d_message_finish(id, (char*)byteArray);
		(*env)->ReleaseByteArrayElements(env, data, byteArray, 0);
	}
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeMessageNull(JNIEnv* env, jclass class,
		jint id) {
	if (id > 0) {
		ejoy2d_message_finish(id, NULL);
	}
}

void Java_com_ejoy2dx_doorkickers_JniProxy_nativeOtherUserInfo(JNIEnv * env,
		jclass class, jint cbid, jstring msg, jint success) {
	if (success > 0) {
		ejoy2d_message_finish(cbid, NULL);
	}
	// else
	// 	ejoy2d_message_error(cbid, msg);
}

