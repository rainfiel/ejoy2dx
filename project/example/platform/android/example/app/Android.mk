
$(call import-add-path,../../../../../../platform/android/module)
$(call import-module,lua)
$(call import-module,ejoy2dx)

LOCAL_PATH:= ./src/main/cpp

LS_C=$(subst $(1)/,,$(wildcard $(1)/*.cpp))
PRJ_SRC:= $(call LS_C,$(LOCAL_PATH))

include $(CLEAR_VARS)

LOCAL_MODULE:= native-lib
LOCAL_SRC_FILES:= $(PRJ_SRC)
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)
LOCAL_C_INCLUDES := $(LOCAL_EXPORT_C_INCLUDES)
LOCAL_C_INCLUDES += "../../../ejoy2d/lua"

LOCAL_SHARED_LIBRARIES  := lua-lib
LOCAL_SHARED_LIBRARIES  += ejoy2dx-lib

include $(BUILD_SHARED_LIBRARY)
