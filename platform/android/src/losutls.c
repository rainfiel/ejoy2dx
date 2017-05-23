#include "liosutil.h"
#include "android_helper.h"
#include "filesystem.h"


#include <stdlib.h>

#define LOG_TAG "-landroidutil-"
#define  CLASS_NAME "com/ejoy2dx/doorkickers/AndroidHelper"
#define  pf_log(...)                __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)
#define  pf_vprint(format, ap)      __android_log_vprint(ANDROID_LOG_DEBUG, LOG_TAG, (format), (ap))

int
lexists(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
  int exists = apk_file_exists(filename);
  pf_log("FH lexists: %s, %d", filename, exists);
  lua_pushboolean(L, exists);
  return 1;
}

int
lread(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);

  pf_log("FH lread: %s", filename);

  unsigned long size;
  char* data = (char*)getFileData(filename, "rb", &size);
  if(data) {
    lua_pushlstring(L, data, size);
    free(data);
  }
  else {
    lua_pushnil(L);
  }

  return 1;
}

int
lwrite(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
  pf_log("FH lwrite: %s", filename);
  size_t data_len;
  const char* content = luaL_checklstring(L, 2, &data_len);

  FILE* fp;
  fp = fopen(filename, "wb");
  fwrite(content, 1, data_len, fp);
  fclose(fp);

  return 0;
}
int
lclear(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
  pf_log("FH lclear: %s", filename);

  // void clearFile(String)
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "clearFile", "(Ljava/lang/String;)V") < 0)
      return 0 ;

  jstring jfilename = (*methodInfo.env)->NewStringUTF(methodInfo.env, filename);
  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, jfilename);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jfilename);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 0;
}

static int
_terminate(lua_State* L) {
  // void terminateProcess()
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "terminateProcess", "()V") < 0) {
    return 0;
  }

  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 0;
}

static int
_device(lua_State* L){
  // string getDeviceID()
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getDeviceID", "()Ljava/lang/String;") < 0) {
    lua_pushnil(L);
    return 1;
  }

  jstring jstr = (jstring)(*methodInfo.env)->CallStaticObjectMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);
  const char* str = (*methodInfo.env)->GetStringUTFChars(methodInfo.env, jstr, NULL);
  lua_pushstring(L, str);

  (*methodInfo.env)->ReleaseStringUTFChars(methodInfo.env, jstr, str);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jstr);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 1;
}

static int
_version(lua_State* L){
  // string getSystemVersion()
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getSystemVersion", "()Ljava/lang/String;") < 0) {
    lua_pushnil(L);
    return 1;
  }

  jstring jstr = (jstring)(*methodInfo.env)->CallStaticObjectMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);

  const char* str = (*methodInfo.env)->GetStringUTFChars(methodInfo.env, jstr, NULL);
  lua_pushstring(L, str);

  (*methodInfo.env)->ReleaseStringUTFChars(methodInfo.env, jstr, str);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jstr);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 1;
}

static int
_memo(lua_State* L) {
  // string getUserID()
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getUserID", "()Ljava/lang/String;") < 0) {
    lua_pushnil(L);
    return 1;
  }

  jstring jstr = (jstring)(*methodInfo.env)->CallStaticObjectMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);

  const char* str = (*methodInfo.env)->GetStringUTFChars(methodInfo.env, jstr, NULL);
  lua_pushstring(L, str);

  (*methodInfo.env)->ReleaseStringUTFChars(methodInfo.env, jstr, str);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jstr);

  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 1;
}

static int
_alert(lua_State* L) {
  // void createAlertDlg(String, String, String)
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "createAlertDlg", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V") < 0) {
    return 0;
  }

  const char* strTitle  = luaL_checkstring(L,1);
  const char* strMsg    = luaL_checkstring(L,2);
  const char* strButton = luaL_checkstring(L,3);

  jstring jStrTitle = (*methodInfo.env)->NewStringUTF(methodInfo.env, strTitle);
  jstring jStrMsg = (*methodInfo.env)->NewStringUTF(methodInfo.env, strMsg);
  jstring jStrButton = (*methodInfo.env)->NewStringUTF(methodInfo.env, strButton);
  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, jStrTitle, jStrMsg, jStrButton);

  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jStrTitle);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jStrMsg);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jStrButton);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 0;
}

static int
_alert_with_callback(lua_State* L) {
  const char* strTitle = luaL_checkstring(L,1);
  const char* strMsg   = luaL_checkstring(L,2);
  int   iid            = luaL_checkinteger(L,4);

  //{{title, ud}, {title, ud}}
  luaL_checktype(L, 3, LUA_TTABLE);
  int count = luaL_len(L, 3);
  int i = 1;

  const char *btnTitle0 = NULL, *btnTitle1 = NULL;
  const char *btnUd0 = NULL, *btnUd1 = NULL;

  for ( ; i <= count; i++) {
    lua_rawgeti(L, 3, i);

    lua_rawgeti(L, -1, 1); // title
    lua_rawgeti(L, -2, 2); // ud

    if (i == 1) {
      btnTitle0 = lua_tostring(L,-2);
      btnUd0 = lua_tostring(L,-1);
    } else if (i == 2) {
      btnTitle1 = lua_tostring(L,-2);
      btnUd1 = lua_tostring(L,-1);
    }

    lua_pop(L,3);
  }

  // void createAlertCBDlg(String, String, int, String, String, String, String)
  struct JniMethodInfo methodInfo;

  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "createAlertCBDlg",
    "(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V") < 0)
  {
      return 0;
  }

  char empty = '\0';
  if (!btnTitle1) btnTitle1 = &empty;
  if (!btnTitle1) btnTitle1 = &empty;

  jstring jStrTitle = (*methodInfo.env)->NewStringUTF(methodInfo.env, strTitle);
  jstring jStrMsg = (*methodInfo.env)->NewStringUTF(methodInfo.env, strMsg);
  jstring jBtnTitle0 = (*methodInfo.env)->NewStringUTF(methodInfo.env, btnTitle0);
  jstring jBtnUd0 = (*methodInfo.env)->NewStringUTF(methodInfo.env, btnUd0);
  jstring jBtnTitle1 = (*methodInfo.env)->NewStringUTF(methodInfo.env, btnTitle1);
  jstring jBtnUd1 = (*methodInfo.env)->NewStringUTF(methodInfo.env, btnUd1);
  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id,
    jStrTitle, jStrMsg, iid, jBtnTitle0, jBtnUd0, jBtnTitle1, jBtnUd1);

  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jStrTitle);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jStrMsg);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnTitle0);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnUd0);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnTitle1);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnUd1);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);
  return 0;
}

static int
_input(lua_State* L) {
  const char* strTitle = luaL_checkstring(L,1);
  int iid = luaL_checkinteger(L, 2);
  const char* cancelButtonTitle = luaL_checkstring(L,3);
  const char* okButtonTitle = luaL_checkstring(L, 4);
  const char* defaultText = luaL_checkstring(L,5);

  int max_len = lua_tointeger(L, 7);
  if(max_len <=0)
	  max_len = 1000;
  // void createAlertTextInputDlg(String, int, String, String, String)
  struct JniMethodInfo methodInfo;

  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "createAlertTextInputDlg",
    "(Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V") < 0)
  {
      return 0;
  }

  jstring jStrTitle = (*methodInfo.env)->NewStringUTF(methodInfo.env, strTitle);
  jstring jBtnOk = (*methodInfo.env)->NewStringUTF(methodInfo.env, okButtonTitle);
  jstring jBtnCancel = (*methodInfo.env)->NewStringUTF(methodInfo.env, cancelButtonTitle);
  jstring jDefaultText = (*methodInfo.env)->NewStringUTF(methodInfo.env, defaultText);

  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id,
    jStrTitle, iid, jBtnOk, jBtnCancel, jDefaultText,max_len);
  
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jStrTitle);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnOk);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jBtnCancel);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jDefaultText);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 0;
}

static int
_mkdir(lua_State* L) {
  // void mkdir(String path)
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "mkdir", "(Ljava/lang/String;)V") < 0) {
    return 0;
  }

  const char* path = luaL_checkstring(L, 1);

  pf_log("_mkdir: %s", path);

  jstring jpath = (*methodInfo.env)->NewStringUTF(methodInfo.env, path);

  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, jpath);

  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jpath);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 0;
}

static int
_get_path(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  const char* mode = luaL_optstring(L, 2, "d");
  pf_log("_get_path, %s, %s", path, mode);
  char ret_path[512];
  if (mode[0] == 'l') {
    strcpy(ret_path, getMemPath());
    strcat(ret_path, "/lib/");
    strcat(ret_path, path);
  } else if (mode[0] == 'c') {
    strcpy(ret_path, getMemPath());
    strcat(ret_path, "/cache/");
    strcat(ret_path, path);
  } else {
    strcpy(ret_path, getMemPath());
    strcat(ret_path, "/doc/");
    strcat(ret_path, path);
  }
  pf_log("ret_path: %s", ret_path);
  lua_pushstring(L, ret_path);
  return 1;
}

static int
_log(lua_State* L) {
  const char* msg = lua_tostring(L, 1);
  if(msg) {
    __android_log_print(ANDROID_LOG_INFO, "ejoy", "++ %s", msg);
  }
  return 0;
}

static int
_post_log2(lua_State* L){
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "httpPost", "(Ljava/lang/String;Ljava/lang/String;)V") < 0) {
    return 0;
  }

  const char* url = luaL_checkstring(L, 1);
  jstring jurl = (*methodInfo.env)->NewStringUTF(methodInfo.env, url);  
  const char* jsonData = luaL_checkstring(L, 2);
  jstring jjsonData = (*methodInfo.env)->NewStringUTF(methodInfo.env, jsonData);

  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, jurl, jjsonData);


  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jurl);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jjsonData);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

   return 0;
}


static int
_open_url(lua_State* L){
  // void openUrl(String url)
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "openUrl", "(Ljava/lang/String;)V") < 0) {
    return 0;
  }

  const char* url = luaL_checkstring(L, 1);
  jstring jurl = (*methodInfo.env)->NewStringUTF(methodInfo.env, url);

  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, jurl);

  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jurl);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 0;
}
static int
_save_to_keychain(lua_State* L) {
	  const char* service = luaL_checkstring(L, 1);
	  const int tableIndex = 2;
	  luaL_checktype(L, tableIndex, LUA_TTABLE);

	  lua_pushnil(L);
	  while (lua_next(L, tableIndex) != 0) {
	    if (lua_isstring(L, -2)) {
	      const char* key = lua_tostring(L, -2);
	      if (lua_isstring(L, -1)) {
	        const char* val = lua_tostring(L, -1);
	        // void saveToKeyChain(String, String)
	        struct JniMethodInfo methodInfo;
	        if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "saveToKeyChain", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V") < 0) {
	          return 0;
	        }

	        jstring jsvr = (*methodInfo.env)->NewStringUTF(methodInfo.env, service);
	        jstring jkey = (*methodInfo.env)->NewStringUTF(methodInfo.env, key);
	        jstring jval = (*methodInfo.env)->NewStringUTF(methodInfo.env, val);

	        (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, jsvr,jkey, jval);
          
          (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jsvr);
          (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jkey);
          (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jval);
	        (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);
	      }
	    }
	    lua_pop(L, 1);
	  }
  return 0;
}
static int
_load_from_keychain(lua_State* L) {
  // string getKeyChainUid()
  const char* service = luaL_checkstring(L, 1);
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getFromKeyChain", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;") < 0) {
    lua_pushnil(L);
    return 1;
  }
  lua_newtable(L);
  jstring str_svr = (*methodInfo.env)->NewStringUTF(methodInfo.env, service);
  int i = 1;
  int len = lua_rawlen(L,2);
  for(i =1; i <= len;++i)
  {
	  lua_rawgeti(L,2,i);
      const char* key = lua_tostring(L, -1);
      jstring jkey = (*methodInfo.env)->NewStringUTF(methodInfo.env, key);
      jstring jval = (jstring)(*methodInfo.env)->CallStaticObjectMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, str_svr,jkey);
      const char* str = (*methodInfo.env)->GetStringUTFChars(methodInfo.env, jval, NULL);

      if(strlen(str) != 0) {
    	  lua_pushstring(L,str);
    	  lua_setfield(L,3,key);
      }
      lua_settop(L,3);
      (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jkey);
      (*methodInfo.env)->ReleaseStringUTFChars(methodInfo.env, jval, str);
      (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jval);
  }
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, str_svr);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 1;
}

static int
_delete_from_keychain(lua_State* L) {
	const char* service = luaL_checkstring(L, 1);
	// void deleteKeyChain()
	struct JniMethodInfo methodInfo;
	if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "deleteKeyChain", "(Ljava/lang/String;)V") < 0)
	  return 0;
	jstring jsvr = (*methodInfo.env)->NewStringUTF(methodInfo.env, service);
	(*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id,jsvr);

	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, jsvr);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);
	return 0;
}

static int
_bundle_version(lua_State* L) {
  // string getUserID()
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getBundleVersion", "()Ljava/lang/String;") < 0) {
    lua_pushnil(L);
    return 1;
  }

  jstring jstr = (jstring)(*methodInfo.env)->CallStaticObjectMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);

  const char* str = (*methodInfo.env)->GetStringUTFChars(methodInfo.env, jstr, NULL);
    lua_pushstring(L, str);

  (*methodInfo.env)->ReleaseStringUTFChars(methodInfo.env, jstr, str);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jstr);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 1;
}

static int
_register_notification(lua_State* L) {
  // void cancelAllLocalNotifications()
  struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "cancelAllLocalNotifications", "()V") < 0)
  {
      return 0;
  }

  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);
  return 0;
}

static int
_schedule_notification(lua_State* L) {
  // void scheduleNotificationWithMsg(String msg, int second)
  struct JniMethodInfo methodInfo;

  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "scheduleNotificationWithMsg", "(Ljava/lang/String;I)V") < 0)
  {
      return 0;
  }

  const char* msg = luaL_checkstring(L, 1);
  int   seconds = luaL_checkinteger(L, 2);

  jstring jmsg = (*methodInfo.env)->NewStringUTF(methodInfo.env, msg);
  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, jmsg, seconds);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jmsg);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

  return 0;
}

static int
_free_memo(lua_State* L) {
  // void getFreeMemory(String msg, int second)
  struct JniMethodInfo methodInfo;

  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getFreeMem", "()I") < 0)
  {
      return 0;
  }
  jint fm = (jint)(*methodInfo.env)->CallStaticIntMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);
  lua_pushnumber(L,fm);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);
  return 1;
}
static int
_used_memo(lua_State* L) {
  // void getFreeMemory(String msg, int second)
  struct JniMethodInfo methodInfo;

  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getUsedMem", "()I") < 0)
  {
      return 0;
  }
  jint fm = (jint)(*methodInfo.env)->CallStaticIntMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);
  lua_pushnumber(L,fm);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);
  return 1;
}

int luaopen_osutil(lua_State* L) {
  luaL_checkversion(L);

  luaL_Reg reg[] = {
    {"terminate", _terminate},
    {"device", _device},
    {"version", _version},
    {"bundle_version",_bundle_version},
    {"free_memory",_free_memo},
    {"used_memory",_used_memo},
    {"memo", _memo},

    // alert & input
    {"alert", _alert},
    {"alert_with_callback", _alert_with_callback},
    {"input", _input},

    // util
    {"log", _log},
    {"post_log2", _post_log2},
    {"open_url", _open_url},
    
    // filesystem
    {"mkdir", _mkdir},
    {"get_path", _get_path},
    {"exists", lexists},
    {"read_file", lread},
    {"write_file", lwrite},
    {"delete_file", lclear},

    {"register_notification", _register_notification},
    {"schedule_notification", _schedule_notification},

    // keychain
    {"save_to_keychain", _save_to_keychain},
    {"load_from_keychain", _load_from_keychain},
    {"delete_from_keychain", _delete_from_keychain},

  	{ NULL, NULL },
  };

  luaL_newlib(L, reg);

  return 1;
}
