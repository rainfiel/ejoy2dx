#include "android_helper.h"

#include "lua.h"
#include "lauxlib.h"

#include <string.h>
#include <stdio.h>
#include <unzip.h>
#include <android/log.h>
#include <sys/time.h>

#define  LOG_TAG    "android_helper"
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)

#define  CLASS_NAME "com/ejoy2dx/doorkickers/AndroidHelper"

char _apkpath[512];
char _mempath[512];
char _sdpath[512];

JavaVM* _javavm = NULL;
AAssetManager* assetmanager = NULL;

void setassetmanager(AAssetManager* a) {
    if (NULL == a) {
        LOGD("setassetmanager : received unexpected nullptr parameter");
        return;
    }
    LOGD("setassetmanager");
    assetmanager = a;
}

void alertOutOfMemory() {
  // void clearFile(String)
 /* struct JniMethodInfo methodInfo;
  if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "createOutOfMemoryDlg", "()V") < 0)
      return;

  (*methodInfo.env)->CallStaticVoidMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id);
  (*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);*/
}

const char* getMemPath() {
	return _mempath;
}

const char* getApkPath() {
    return _apkpath;
}

const char* getSdPath() {
    return _sdpath;
}

int apk_file_exists(const char * file)
{
		if (!file) return 0;

		if (file[0] != '/')
		{
			// read from apk
			if (assetmanager != NULL) {
				char filepath[255] = "assets/";
				if (!_apkpath) return 0;
				unzFile pFile = unzOpen(_apkpath);
				if (!pFile) return 0;
				int nRet = unzLocateFile(pFile, strcat(filepath, file), 1);
				if (UNZ_OK != nRet) return 0;
				unzClose(pFile);
				return 1;
			} else {
				AAsset* aa = AAssetManager_open(assetmanager, file, AASSET_MODE_UNKNOWN);
				if (aa)
				{
					AAsset_close(aa);
					return 1;
				} else {
					return 0;
				}
			}
		}
		else
		{
			// read rrom other path than user set it
			FILE *fp = fopen(file, "rb");
			if (fp)
			{
				fclose(fp);
				return 1;
			}
			else
				return 0;
		}

		return 0;
}

unsigned char* getFileData(const char* filename,
						   const char* mode,
						   unsigned long * size)
{
	unsigned char* data = 0;

	if ((! filename) || (! mode))
	{
		return NULL;
	}

	if (filename[0] != '/')
	{
		// read from apk
		if (assetmanager == NULL) {
			char filepath[255] = "assets/";
			data = getFileDataFromZip(_apkpath, strcat(filepath, filename), size);
		} else {
			data = getFileDataFromAssets(filename, size);
		}
	}
	else
	{
		do
		{
			// read rrom other path than user set it
			FILE *fp = fopen(filename, mode);
			if (!fp) break;

			unsigned long sz;
			fseek(fp,0,SEEK_END);
			sz = ftell(fp);
			fseek(fp,0,SEEK_SET);
			data = (unsigned char*) malloc(sz);
			if(!data) {
				LOGD("FAILE to load data %s",filename);
				return NULL;
			}
			sz = fread(data,sizeof(unsigned char), sz,fp);
			fclose(fp);

			if (size)
			{
				*size = sz;
			}
		} while (0);
	}

	return data;
}

unsigned char* getFileDataFromZip(const char* zipfilepath, const char* filename,
								  unsigned long * size)
{
	unsigned char * buffer = NULL;
	unzFile file = NULL;
	*size = 0;

	do
	{
		if (!zipfilepath || !filename) break;
		if (strlen(zipfilepath) == 0) break;

		file = unzOpen(zipfilepath);
		if (!file) break;

		int nRet = unzLocateFile(file, filename, 1);
		if (UNZ_OK != nRet) break;

		char szFilePathA[260];
		unz_file_info FileInfo;
		nRet = unzGetCurrentFileInfo(file, &FileInfo, szFilePathA, sizeof(szFilePathA), NULL, 0, NULL, 0);
		if (UNZ_OK != nRet) break;

		nRet = unzOpenCurrentFile(file);
		if (UNZ_OK != nRet) break;

		buffer = (unsigned char*)malloc(FileInfo.uncompressed_size);
		if(!buffer) {
			return NULL;
		}
		int nSize = 0;
		nSize = unzReadCurrentFile(file, buffer, FileInfo.uncompressed_size);

		*size = FileInfo.uncompressed_size;

		unzCloseCurrentFile(file);
	} while (0);

	if (file)
	{
		unzClose(file);
	}

	return buffer;
}

///////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
// java vm helper function
//////////////////////////////////////////////////////////////////////////

static int
getEnv(JNIEnv **env)
{
  if ((*_javavm)->GetEnv(_javavm, (void**)env, JNI_VERSION_1_4) != JNI_OK) {
    LOGD("Failed to get the environment using GetEnv()");
    return -1;
  }

  if ((*_javavm)->AttachCurrentThread(_javavm, env, 0) < 0) {
  	LOGD("Failed to get the environment using AttachCurrentThread()");
  	return -1;
  }

  return 0;
}

static jclass
getClassID_(const char *className, JNIEnv *env) {
  JNIEnv *pEnv = env;
  jclass ret = 0;

  do {
    if (! pEnv) {
    if (getEnv(&pEnv) < 0)
      break;
    }

    ret = (*pEnv)->FindClass(pEnv, className);
    if (! ret) {
      LOGD("Failed to find class of %s", className);
      break;
    }
  } while (0);

  return ret;
}

static int
getStaticMethodInfo_(struct JniMethodInfo* methodinfo, const char *className, const char *methodName, const char *paramCode) {
  jmethodID method_id = 0;
  JNIEnv *pEnv = 0;
  int bRet = -1;

  do {
    if (getEnv(&pEnv) < 0)
      break;

    jclass class_id = getClassID_(className, pEnv);

    method_id = (*pEnv)->GetStaticMethodID(pEnv, class_id, methodName, paramCode);
    if (! method_id) {
      LOGD("Failed to find static method id of %s", methodName);
      break;
    }

    methodinfo->class_id = class_id;
    methodinfo->env = pEnv;
    methodinfo->method_id = method_id;

    bRet = 0;
  } while (0);

  return bRet;
}

static int
getMethodInfo_(struct JniMethodInfo* methodinfo, const char *className, const char *methodName, const char *paramCode) {
  jmethodID method_id = 0;
  JNIEnv *pEnv = 0;
  int bRet = -1;

  do {
    if (getEnv(&pEnv) < 0)
      break;

      jclass class_id = getClassID_(className, pEnv);

      method_id = (*pEnv)->GetMethodID(pEnv, class_id, methodName, paramCode);
      if (! method_id) {
        LOGD("Failed to find method id of %s", methodName);
        break;
      }

      methodinfo->class_id = class_id;
      methodinfo->env = pEnv;
      methodinfo->method_id = method_id;

      bRet = 0;
  } while (0);

  return bRet;
}

JavaVM*
getJavaVM() {
  return _javavm;
}

void
setJavaVM(JavaVM *javaVM) {
  _javavm = javaVM;
}

jclass
getClassID(const char *className, JNIEnv *env) {
  return getClassID_(className, env);
}

int
getStaticMethodInfo(struct JniMethodInfo* methodinfo, const char *className, const char *methodName, const char *paramCode) {
  return getStaticMethodInfo_(methodinfo, className, methodName, paramCode);
}

int
getMethodInfo(struct JniMethodInfo* methodinfo, const char *className, const char *methodName, const char *paramCode) {
  return getMethodInfo_(methodinfo, className, methodName, paramCode);
}

unsigned char*
getFileDataFromAssets(const char* filename, unsigned long* size) {
	unsigned char* data = 0;
	do
	{
		/*获取文件名并打开*/
		AAsset* asset = AAssetManager_open(assetmanager, filename, AASSET_MODE_UNKNOWN);
		if( asset == NULL )
		{
			// LOGD("getFileData file not exist %s", filename);
			return NULL;
		}

		/*获取文件大小*/
		off_t bufferSize = AAsset_getLength(asset);

		char bom[3];
		int readed = AAsset_read(asset, bom, 3);
		if (readed == 3 && (bom[0] == 0XEF && bom[1] == 0XBB && bom[2] == 0XBF)) {
			bufferSize -= 3;
		} else {
			AAsset_seek(asset, 0, SEEK_SET);
		}

		data = (unsigned char *)malloc(bufferSize);
		int numBytesRead = AAsset_read(asset, data, bufferSize);
		*size = bufferSize;

		/*关闭文件*/
		AAsset_close(asset);

	} while (0);

	return data;
}
