
#include <stdbool.h>

#include "opengl.h"
#include "ejoy2dgame.h"
#include "fault.h"
#include "screen.h"
#include "winfw.h"
#include "lualibs.h"

#include <lauxlib.h>

#include <stdlib.h>
#include <stdio.h>

#ifndef LOGIC_FRAME
#define LOGIC_FRAME 30
#endif

struct WINDOWGAME {
	struct game *game;
	int intouch;
};

static struct WINDOWGAME *G = NULL;
static struct STARTUP_INFO *STARTUP = NULL;

#define IOS 1
#define WINDOWS 2

#if EJOY2D_OS == IOS
static const char * startscript =
"local path, script, startup = ...\n"

"script = script or [[main.lua]]\n"
"if not path then print('PLEASE SPECIFY THE WORK DIRECTORY') end\n"
"local fw=require(\"ejoy2d.framework\")\n"
"fw.WorkDir = path\n"
"fw.GameInfo = startup\n"

"local script_root = path .. [[/?.lua;]] .. path .. [[/?/init.lua;./?.lua;./?/init.lua]]\n"
"local script_project = path .. [[/script/?.lua;]].. path .. [[/script]] .. [[/?/init.lua;./?.lua;./?/init.lua]]\n"
"package.path = script_root..[[;]]..script_project\n"

"require([[script]])\n"
"local f = assert(loadfile(path..[[/script/]]..script))\n"
"f(script)\n"
;
#else
static const char * startscript =
"local path, script, startup = ...\n"

"script = script or [[main.lua]]\n"
"if not path then print('PLEASE SPECIFY THE WORK DIRECTORY') end\n"
"path = string.match(path,[[(.*)\\[^\\]*$]])\n"
"local fw=require(\"ejoy2d.framework\")\n"
"fw.WorkDir = path\n"
"fw.GameInfo = startup\n"

//ejoy2dx path
"local ej2dx = path .. [[\\..\\..\\src]] .. [[\\?.lua;]] .. path .. [[\\..\\..\\src]] .. [[\\?\\init.lua;.\\?.lua;.\\?\\init.lua]]\n"
//ejoy2d path
"local ej2d  = path .. [[\\..\\..\\ejoy2d]] .. [[\\?.lua;]] .. path .. [[\\..\\..\\ejoy2d]] .. [[\\?\\init.lua;.\\?.lua;.\\?\\init.lua]]\n"
//user path
"local usr = path .. [[\\script\\?.lua;]].. path .. [[\\script]] .. [[\\?\\init.lua;.\\?.lua;.\\?\\init.lua]]\n"
"package.path = ej2dx..[[;]]..ej2d..[[;]]..usr\n"

"require([[script]])\n"
"local f = assert(loadfile(path..[[\\script\\]]..script))\n"
"f(script)\n"
;
#endif

static struct WINDOWGAME *
create_game() {
	struct WINDOWGAME * g = (struct WINDOWGAME *)malloc(sizeof(*g));
	g->game = ejoy2d_game();
	g->intouch = 0;
	return g;
}

static int
traceback(lua_State *L) {
	const char *msg = lua_tostring(L, 1);
	if (msg)
		luaL_traceback(L, L, msg, 1);
	else if (!lua_isnoneornil(L, 1)) {
	if (!luaL_callmeta(L, 1, "__tostring"))
		lua_pushliteral(L, "(no error message)");
	}
	return 1;
}

static void
push_startup_info(lua_State* L, struct STARTUP_INFO* start) {
	lua_newtable(L);
	lua_pushnumber(L, start->orix);
	lua_setfield(L, -2, "orix");
	lua_pushnumber(L, start->oriy);
	lua_setfield(L, -2, "oriy");

	lua_pushnumber(L, start->width);
	lua_setfield(L, -2, "width");
	lua_pushnumber(L, start->height);
	lua_setfield(L, -2, "height");

	lua_pushnumber(L, start->scale);
	lua_setfield(L, -2, "scale");
	lua_pushinteger(L, start->reload_count);
	lua_setfield(L, -2, "reload_count");

	if (start->serialized)	
		lua_pushlightuserdata(L, start->serialized);
	else
		lua_pushnil(L);
	lua_setfield(L, -2, "serialized");

	lua_pushinteger(L, LOGIC_FRAME);
	lua_setfield(L, -2, "logic_frame");
}

void
ejoy2d_win_init(struct STARTUP_INFO* startup) {
	//free it
	STARTUP = startup;
	G = create_game();

	screen_init(startup->width,startup->height,startup->scale);
	lua_State *L = ejoy2d_game_lua(G->game);
	
	init_lua_libs(L);
	init_user_lua_libs(L);

	lua_pushcfunction(L, traceback);
	int tb = lua_gettop(L);
	int err = luaL_loadstring(L, startscript);
	if (err) {
		const char *msg = lua_tostring(L,-1);
		fault("%s", msg);
	}

	lua_pushstring(L, startup->folder);
	lua_pushstring(L, startup->script);

	push_startup_info(L, startup);
	err = lua_pcall(L, 3, 0, tb);
	if (err) {
		const char *msg = lua_tostring(L,-1);
		fault("%s", msg);
	}
	lua_pop(L,1);

	ejoy2d_game_logicframe(LOGIC_FRAME);
	ejoy2d_game_start(G->game);
}

static void
ejoy2d_check_reload() {
	if (!G || !STARTUP) return;

	lua_State *L = ejoy2d_game_lua(G->game);
	lua_getfield(L, LUA_REGISTRYINDEX, "ejoy_reload");
	int reload_flag = lua_toboolean(L, -1);
	lua_pop(L, 1);

	if (reload_flag) {
		STARTUP->reload_count = STARTUP->reload_count + 1;

		lua_getfield(L, LUA_REGISTRYINDEX, "seraized_texture");
		STARTUP->serialized = lua_touserdata(L, -1);
		lua_pop(L, 1);

		free(G);
		ejoy2d_win_init(STARTUP);
	}

}

void
ejoy2d_win_update(float delta) {
	ejoy2d_game_update(G->game, delta);
	ejoy2d_check_reload();
}

void
ejoy2d_win_frame() {
	ejoy2d_game_drawframe(G->game);
}

int
ejoy2d_win_touch(int x, int y,int touch) {
	switch (touch) {
	case TOUCH_BEGIN:
		G->intouch = 1;
		break;
	case TOUCH_END:
		G->intouch = 0;
		break;
	case TOUCH_MOVE:
		if (!G->intouch) {
			return 0;
		}
		break;
	}
	// windows only support one touch id (0)
	int id = 0;
	return ejoy2d_game_touch(G->game, id, x,y,touch);
}

void
ejoy2d_win_gesture(int type, int x1, int y1, int x2, int y2, int state) {
	ejoy2d_game_gesture(G->game, type, x1, y1, x2, y2, state);
}

void
ejoy2d_win_view_layout(int stat, float x, float y, float width, float height) {
	ejoy2d_game_view_layout(G->game, stat, x, y, width, height);
}
