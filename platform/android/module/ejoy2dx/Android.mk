LOCAL_PATH:= $(call my-dir)/../../../../ejoy2d/lib
HELP_PATH := $(LOCAL_PATH)/../../platform/android/src
X_PATH := $(LOCAL_PATH)/../../src/clib

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

SRC_SUFFIX := *.c 
LS_C=$(subst $(1)/,,$(call rwildcard, $(1), $(SRC_SUFFIX)))

###############################################

include $(CLEAR_VARS)

EJ_SRC := $(call LS_C,$(LOCAL_PATH))
EJ_SRC := $(filter-out lejoy2dcore.c, $(EJ_SRC))

HELP_SRC := $(call LS_C,$(HELP_PATH))
HELP_SRC := $(patsubst %.c,../../platform/android/src/%.c,$(HELP_SRC))  
EJ_SRC += $(HELP_SRC)

X_SRC := $(call LS_C,$(X_PATH))
X_SRC := $(patsubst %.c,../../src/clib/%.c,$(X_SRC))  
EJ_SRC += $(X_SRC)

$(warning $(EJ_SRC))

LOCAL_MODULE:= ejoy2dx-lib
LOCAL_SRC_FILES:= $(EJ_SRC)

LOCAL_CFLAGS := -std=c99
LOCAL_LDLIBS := -llog -lGLESv2

LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
LOCAL_EXPORT_C_INCLUDES += $(LOCAL_PATH)/render
LOCAL_EXPORT_C_INCLUDES += $(HELP_PATH)
LOCAL_C_INCLUDES := $(LOCAL_EXPORT_C_INCLUDES)

LOCAL_SHARED_LIBRARIES  := lua-lib

#include $(BUILD_STATIC_LIBRARY)
include $(BUILD_SHARED_LIBRARY)
