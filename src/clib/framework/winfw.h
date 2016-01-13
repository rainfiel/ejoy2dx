#ifndef ejoy2d_windows_fw_h
#define ejoy2d_windows_fw_h

#include <lua.h>

#define STATE_POSSIBLE    (0)
#define STATE_BEGAN       (1)
#define STATE_CHANGED     (2)
#define STATE_ENDED       (3)
#define STATE_CANCELLED   (4)
#define STATE_FAILED      (5)

#define TOUCH_BEGIN 0
#define TOUCH_END 1
#define TOUCH_MOVE 2

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

void ejoy2d_win_init(struct STARTUP_INFO* startup);
void ejoy2d_win_frame();
void ejoy2d_win_update(float delta);
void ejoy2d_win_sync_frame();
int ejoy2d_win_touch(int x, int y,int touch);
void ejoy2d_win_gesture(int type, float x1, float y1, float x2, float y2, int state);
void ejoy2d_win_view_layout(int stat, float x, float y, float w, float h);
bool ejoy2d_win_auto_rotate();

#endif
