#ifndef ejoy2d_windows_fw_h
#define ejoy2d_windows_fw_h

#include <lua.h>
#include <stdbool.h>

#define STATE_POSSIBLE    (0)
#define STATE_BEGAN       (1)
#define STATE_CHANGED     (2)
#define STATE_ENDED       (3)
#define STATE_CANCELLED   (4)
#define STATE_FAILED      (5)

#define TOUCH_BEGIN 0
#define TOUCH_END 1
#define TOUCH_MOVE 2
#define TOUCH_CANCEL 3

#define ejoy2d_message_finish(i,d) ejoy2d_fw_message((i),"FINISH",(d),0)
#define ejoy2d_message_cancel(i) ejoy2d_fw_message((i),"CANCEL",NULL,0)

struct STARTUP_INFO{
	float orix, oriy;
	float width, height;
	float scale;
	const char* folder;
	const char* lua_root;
	const char* script;
	const char* user_data;
	void* serialized;
	int reload_count;
	bool auto_rotate;
};

void init_user_lua_libs(lua_State* L);

void ejoy2d_fw_init(struct STARTUP_INFO* startup);
void ejoy2d_fw_frame();
void ejoy2d_fw_update(float delta);
int ejoy2d_fw_touch(int x, int y,int touch, int id);
void ejoy2d_fw_gesture(int type, float x1, float y1, float x2, float y2, int state);
void ejoy2d_fw_view_layout(int stat, float x, float y, float w, float h);
void ejoy2d_fw_message(int ID,const char* msg,const char* data, lua_Number n);
void ejoy2d_fw_pause();
void ejoy2d_fw_resume();
void ejoy2d_fw_close();

bool ejoy2d_fw_auto_rotate();
bool ejoy2d_fw_simul_gesture();

#endif
