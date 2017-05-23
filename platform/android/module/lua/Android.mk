LOCAL_PATH:= $(call my-dir)/../../../../ejoy2d/lua

LS_C=$(subst $(1)/,,$(wildcard $(1)/*.c))
LUA_SRC:= $(call LS_C,$(LOCAL_PATH))

include $(CLEAR_VARS)

#required!!!!
LOCAL_CFLAGS    := -D"getlocaledecpoint()='.'"
LOCAL_CFLAGS    += -D"lua_getlocaledecpoint()='.'"
LOCAL_CFLAGS 		+= -std=c99


ifneq ($(TARGET_ARCH_ABI),mips64)
	ifneq ($(TARGET_ARCH_ABI),x86_64)
		ifneq ($(TARGET_ARCH_ABI),arm64-v8a)
  		LOCAL_CFLAGS 		+= -D"log2(x)=log(x)/log(2.0)"
  	endif
  endif
endif

LOCAL_MODULE:= lua-lib
LOCAL_SRC_FILES:= $(LUA_SRC)
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
LOCAL_C_INCLUDES := $(LOCAL_EXPORT_C_INCLUDES)

include $(BUILD_STATIC_LIBRARY)
