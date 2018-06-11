#include "liosutil.h"
#include "android_helper.h"
#include "filesystem.h"


#include <stdlib.h>

#define LOG_TAG "-landroidutil-"
#define  pf_log(...)                __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)
#define  pf_vprint(format, ap)      __android_log_vprint(ANDROID_LOG_DEBUG, LOG_TAG, (format), (ap))

#define _STR_VALUE(arg)	#arg
#define STR_VALUE(name) _STR_VALUE(name)
#define  CLASS_NAME "com/ejoy2dx/" STR_VALUE(PROJECT_NAME) "/AndroidHelper"

static int _input(lua_State* L) {
	const char* strTitle = luaL_checkstring(L,1);
	int iid = luaL_checkinteger(L, 2);
	const char* cancelButtonTitle = luaL_optstring(L,3, NULL);
	const char* okButtonTitle = luaL_checkstring(L, 4);
	const char* defaultText = luaL_checkstring(L,5);
	int style = (int)luaL_optinteger(L, 6, 0);
	int max_len = (int)luaL_optinteger(L, 7, 256);

	// void createAlertTextInputDlg(String, int, String, String, String)
	struct JniMethodInfo methodInfo;

	if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "createAlertTextInputDlg",
			"(Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
			< 0) {
		return 0;
	}

	jstring jStrTitle = (*methodInfo.env)->NewStringUTF(methodInfo.env,
			strTitle);
	jstring jBtnOk = (*methodInfo.env)->NewStringUTF(methodInfo.env,
			okButtonTitle);
	jstring jBtnCancel = (*methodInfo.env)->NewStringUTF(methodInfo.env,
			cancelButtonTitle);
	jstring jDefaultText = (*methodInfo.env)->NewStringUTF(methodInfo.env,
			defaultText);
	(*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id,
			methodInfo.method_id, jStrTitle, iid, jBtnOk, jBtnCancel,
			jDefaultText);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, jStrTitle);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnOk);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnCancel);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, jDefaultText);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

	return 0;
}


int luaopen_input(lua_State* L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {		
		{"input", _input},
		{NULL, NULL}
	};

	luaL_newlib(L, l);
	return 1;
}
