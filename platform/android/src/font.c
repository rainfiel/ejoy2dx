#include "label.h"

#include <string.h>
#include <assert.h>

#include "android_helper.h"

#define  CLASS_NAME "com/ejoy2dx/doorkickers/AndroidHelper"

static int font_size_;
static const char* cur_str;
static char tmp_data[128 * 128];
static int data_size = 0;
static int ww = 0;
static int hh = 0;

void font_size(const char *str, int unicode, struct font_context * ctx)
{
	struct JniMethodInfo methodInfo;
	if (getStaticMethodInfo(&methodInfo, CLASS_NAME, "getTextImage", "([BII)Lcom/ejoy2dx/doorkickers/ImageData;") < 0) {
		return;
	}
	jbyteArray bArray = (*methodInfo.env)->NewByteArray(methodInfo.env, strlen(str));
	(*methodInfo.env)->SetByteArrayRegion(methodInfo.env, bArray, 0, strlen(str), (jbyte *)str);
	jobject jImageData = (jstring)(*methodInfo.env)->CallStaticObjectMethod(methodInfo.env, methodInfo.class_id, methodInfo.method_id, bArray, font_size_, 0xffffffff);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, bArray);
	(*methodInfo.env)->DeleteLocalRef(methodInfo.env, methodInfo.class_id);

	if (jImageData != NULL)
    {
		jclass cls_imgdata = (*methodInfo.env)->FindClass(methodInfo.env, "com/ejoy2dx/doorkickers/ImageData");
		jfieldID id_pixels = (*methodInfo.env)->GetFieldID(methodInfo.env, cls_imgdata, "pixels", "[B");
		jbyteArray jPixelsArray = (*methodInfo.env)->GetObjectField(methodInfo.env, jImageData, id_pixels);
		jsize len = (*methodInfo.env)->GetArrayLength(methodInfo.env, jPixelsArray);
		jbyte* jPixels = (*methodInfo.env)->GetByteArrayElements(methodInfo.env, jPixelsArray, JNI_FALSE);
		if (len > 0 && len < 16384)
		{
			cur_str = str;
			data_size = len;
			memcpy(tmp_data, jPixels, data_size);
		}

		(*methodInfo.env)->ReleaseByteArrayElements(methodInfo.env, jPixelsArray, jPixels, 0);

		jfieldID id_width = (*methodInfo.env)->GetFieldID(methodInfo.env, cls_imgdata, "width", "I");
		ctx->w = (*methodInfo.env)->GetIntField(methodInfo.env, jImageData, id_width);
		ww = ctx->w;
		jfieldID id_height = (*methodInfo.env)->GetFieldID(methodInfo.env, cls_imgdata, "height", "I");
		ctx->h = (*methodInfo.env)->GetIntField(methodInfo.env, jImageData, id_height);
        (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jImageData);
        // (*methodInfo.env)->DeleteLocalRef(methodInfo.env, id_pixels);
        (*methodInfo.env)->DeleteLocalRef(methodInfo.env, cls_imgdata);
        (*methodInfo.env)->DeleteLocalRef(methodInfo.env, jPixelsArray);

		hh = ctx->h;
    }
}

void font_glyph(const char * str, int unicode, void * buffer, struct font_context * ctx)
{
    int i =0;
    assert(str == cur_str);
    for(i =0; i < hh;++i)
    {
        memcpy(buffer + i * ctx->w,tmp_data + i * ww,ww);
    }
}

void font_create(int fz, struct font_context *ctx)
{
    font_size_ = fz;
    ctx->font = (void*)-1;
    ctx->dc = (void*)-1;
}

void font_release(struct font_context *ctx)
{

}
