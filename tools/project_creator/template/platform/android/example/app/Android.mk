
FRAMEWORKS := $(call my-dir)/../../../../../../src/clib/framework
PRJ_COMMON := $(call my-dir)/../../../common
AND_COMMON := $(call my-dir)/../../../../../../platform/android/prj_src

$(call import-add-path,../../../../../../platform/android/module)
$(call import-module,lua)
$(call import-module,ejoy2dx)

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

SRC_SUFFIX := *.c 
LS_C=$(subst $(1)/,,$(call rwildcard, $(1), $(SRC_SUFFIX)))

#######################################
LOCAL_PATH:=$(FRAMEWORKS)
PRJ_SRC:=$(call LS_C,$(LOCAL_PATH))

include $(CLEAR_VARS)

LOCAL_MODULE:= framework-static
LOCAL_SRC_FILES:= $(PRJ_SRC)
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
LOCAL_C_INCLUDES := $(LOCAL_EXPORT_C_INCLUDES)
LOCAL_C_INCLUDES += "../../../ejoy2d/lua"
LOCAL_C_INCLUDES += $(FRAMEWORKS)

LOCAL_CFLAGS := -DEJOY2D_OS=ANDROID

LOCAL_SHARED_LIBRARIES  := ejoy2dx-lib

include $(BUILD_STATIC_LIBRARY)

#######################################


LOCAL_PATH:=$(PRJ_COMMON)
PRJ_SRC:=$(call LS_C,$(LOCAL_PATH))

include $(CLEAR_VARS)

LOCAL_MODULE:= common-static
LOCAL_SRC_FILES:= $(PRJ_SRC)
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
LOCAL_C_INCLUDES := $(LOCAL_EXPORT_C_INCLUDES)

LOCAL_CFLAGS := -DEJOY2D_OS=ANDROID

LOCAL_SHARED_LIBRARIES  := ejoy2dx-lib

include $(BUILD_STATIC_LIBRARY)

#######################################
LOCAL_PATH:=$(AND_COMMON)

PRJ_SRC:=$(call LS_C,$(LOCAL_PATH))

#$(warning $(PRJ_SRC))

include $(CLEAR_VARS)

LOCAL_MODULE:= native-lib
LOCAL_SRC_FILES:= $(PRJ_SRC)
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
LOCAL_C_INCLUDES := $(LOCAL_EXPORT_C_INCLUDES)
LOCAL_C_INCLUDES += "../../../ejoy2d/lua"
LOCAL_C_INCLUDES += $(FRAMEWORKS)
LOCAL_C_INCLUDES += $(PRJ_COMMON)

LOCAL_LDLIBS := -landroid -llog
LOCAL_CFLAGS := -DEJOY2D_OS=ANDROID

LOCAL_SHARED_LIBRARIES  := ejoy2dx-lib
LOCAL_WHOLE_STATIC_LIBRARIES  := framework-static common-static

include $(BUILD_SHARED_LIBRARY)
