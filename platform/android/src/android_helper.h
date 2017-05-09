#ifndef ANDROID_HELPER_H
#define ANDROID_HELPER_H

#include <android/log.h>
#include <jni.h>

// for native asset manager
#include <sys/types.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>

void alertOutOfMemory();
void setassetmanager(AAssetManager* a);

const char* getMemPath();
const char* getApkPath();
const char* getSdPath();

int apk_file_exists(const char * file);
unsigned char* getFileData(const char* filename, 
						   const char* mode, 
						   unsigned long* size);
unsigned char* getFileDataFromZip(const char* zipfilepath, 
								  const char* filename, 
								  unsigned long* size);
unsigned char*
getFileDataFromAssets(const char* filename,
						unsigned long* size);

struct JniMethodInfo
{
  JNIEnv*    env;
  jclass     class_id;
  jmethodID  method_id;
};

JavaVM* getJavaVM();
void setJavaVM(JavaVM *javaVM);
jclass getClassID(const char *className, JNIEnv *env);
int getStaticMethodInfo(struct JniMethodInfo* methodinfo, const char *className, const char *methodName, const char *paramCode);
int getMethodInfo(struct JniMethodInfo* methodinfo, const char *className, const char *methodName, const char *paramCode);

#endif // ANDROID_HELPER_H
