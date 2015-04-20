#include <windows.h>

#include <GL/glew.h>
#include <GL/wglew.h>
#include <string.h>
#include <stdlib.h>
#include <mmsystem.h>
#include <lauxlib.h>
#include "winfw.h"

#define CLASSNAME L"EJOY"
#define WINDOWNAME L"EJOY2D"
#define WINDOWSTYLE (WS_OVERLAPPEDWINDOW & ~WS_THICKFRAME & ~WS_MAXIMIZEBOX)

int luaopen_sound(lua_State* L);
int luaopen_world(lua_State *L);

static void
_register(lua_State *L, lua_CFunction func, const char * libname) {
  luaL_requiref(L, libname, func, 0);
  lua_pop(L, 1);
}

void init_user_lua_libs(lua_State *L) {
	_register(L, luaopen_sound, "dk.sound.m");
	_register(L, luaopen_world, "dk.world.m");
}

static DWORD g_lastTime = 0;
static int g_disable_gesture = 0;

struct EVENT_STAT {
	int btn_down;
	int last_x;
	int last_y;
	int disable_gesture;
	int is_pan;
};

static EVENT_STAT g_event_stat;
static void
reset_event_stat() {
	g_event_stat.btn_down = 0;
	g_event_stat.last_x = 0;
	g_event_stat.last_y = 0;
	g_event_stat.disable_gesture = 0;
	g_event_stat.is_pan = 0;
}

static void
set_pixel_format_to_hdc(HDC hDC)
{
	int color_deep;
	PIXELFORMATDESCRIPTOR pfd;

	color_deep = GetDeviceCaps(hDC, BITSPIXEL);
	
	memset(&pfd, 0, sizeof(pfd));
	pfd.nSize = sizeof(pfd);
	pfd.nVersion = 1;
	pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
	pfd.iPixelType	= PFD_TYPE_RGBA;
	pfd.cColorBits	= color_deep;
	pfd.cDepthBits	= 0;
	pfd.cStencilBits = 0;
	pfd.iLayerType	= PFD_MAIN_PLANE;

	int pixelFormat = ChoosePixelFormat(hDC, &pfd);

	SetPixelFormat(hDC, pixelFormat, &pfd);
}

static void
init_window(HWND hWnd) {
	HDC hDC = GetDC(hWnd);

	set_pixel_format_to_hdc(hDC);
	HGLRC glrc = wglCreateContext(hDC);

	if (glrc == 0) {
		exit(1);
	}

	wglMakeCurrent(hDC, glrc);

	if ( glewInit() != GLEW_OK ) {
		exit(1);
	}
	
	reset_event_stat();
	glViewport(0, 0, WIDTH, HEIGHT);

	ReleaseDC(hWnd, hDC);
}

static void
update_frame(HDC hDC) {
	ejoy2d_win_frame();
	SwapBuffers(hDC);

}

static void
get_xy(LPARAM lParam, int *x, int *y) {
	*x = (short)(lParam & 0xffff); 
	*y = (short)((lParam>>16) & 0xffff); 
}

LRESULT CALLBACK 
WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message) {
	case WM_CREATE:
		init_window(hWnd);
		SetTimer(hWnd,0,10,NULL);
		break;
	case WM_PAINT: {
		if (GetUpdateRect(hWnd, NULL, FALSE)) {
			HDC hDC = GetDC(hWnd);
			update_frame(hDC);
			ValidateRect(hWnd, NULL);
			ReleaseDC(hWnd, hDC);
		}
		return 0;
	}
	case WM_TIMER : {
		DWORD now = timeGetTime();
		if (g_lastTime == 0) {
			g_lastTime = now;
		} else {
			float seconds = float((now-g_lastTime)/1000.f);
			ejoy2d_win_update(seconds);
			InvalidateRect(hWnd, NULL , FALSE);
			g_lastTime = now;
		}
		
		break;
	}
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
	case WM_LBUTTONUP: {
		int x,y;
		get_xy(lParam, &x, &y); 
		if (!g_event_stat.disable_gesture) {
			if (g_event_stat.is_pan) {
				ejoy2d_win_gesture(1, x-g_event_stat.last_x, y-g_event_stat.last_y, x, y, 3); //PAN
			} else {
				ejoy2d_win_gesture(2, x, y, 0, 0, 3); //TAP
			}
		} else {
			ejoy2d_win_touch(x, y, TOUCH_END);
		}
		reset_event_stat();
		break;
	}
	case WM_LBUTTONDOWN: {
		int x,y;
		get_xy(lParam, &x, &y); 
		g_event_stat.btn_down = 1;
		g_event_stat.disable_gesture = ejoy2d_win_touch(x,y,TOUCH_BEGIN);
		g_event_stat.last_x = x;
		g_event_stat.last_y = y;
		break;
	}
	case WM_MOUSEMOVE: {
		if (g_event_stat.btn_down) {
			int x,y;
			get_xy(lParam, &x, &y); 
			if (g_event_stat.disable_gesture) {
				ejoy2d_win_touch(x,y,TOUCH_MOVE);
			} else {
				int stat = 0;
				if (!g_event_stat.is_pan) {
					stat = 1; // begin
					g_event_stat.is_pan = 1;
				}	else {
					stat = 2; //change
				}
				ejoy2d_win_gesture(1, x-g_event_stat.last_x, y-g_event_stat.last_y, x, y, stat);
			}
			g_event_stat.last_x = x;
			g_event_stat.last_y = y;
		}
		break;
	}
	case WM_MOUSEWHEEL: {
		short delta = GET_WHEEL_DELTA_WPARAM(wParam);
		if (delta < 0)
			ejoy2d_win_gesture(3, 0, 0, 0.95, 0, 1); //PINCH
		else
			ejoy2d_win_gesture(3, 0, 0, 1.05, 0, 1);
		break;
	}
	}
	return DefWindowProcW(hWnd, message, wParam, lParam);
}

static void
register_class()
{
	WNDCLASSW wndclass;

	wndclass.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
	wndclass.lpfnWndProc = WndProc;
	wndclass.cbClsExtra = 0;
	wndclass.cbWndExtra = 0;
	wndclass.hInstance = GetModuleHandleW(0);
	wndclass.hIcon = 0;
	wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
	wndclass.hbrBackground = 0;
	wndclass.lpszMenuName = 0; 
	wndclass.lpszClassName = CLASSNAME;

	RegisterClassW(&wndclass);
}

static HWND
create_window(int w, int h) {
	RECT rect;

	rect.left=0;
	rect.right=w;
	rect.top=0;
	rect.bottom=h;

	AdjustWindowRect(&rect,WINDOWSTYLE,0);

	HWND wnd=CreateWindowExW(0,CLASSNAME,WINDOWNAME,
		WINDOWSTYLE, CW_USEDEFAULT,0,
		rect.right-rect.left,rect.bottom-rect.top,
		0,0,
		GetModuleHandleW(0),
		0);

	return wnd;
}

int
main(int argc, char *argv[]) {
	register_class();
	HWND wnd = create_window(WIDTH,HEIGHT);

	struct STARTUP_INFO* startup = (struct STARTUP_INFO*)malloc(sizeof(struct STARTUP_INFO));
	startup->folder = "";
	startup->script = NULL;
	if (argc >= 2){
		startup->folder = argv[1];
		startup->script = NULL;
	} 
	if (argc >= 3) {
		startup->script = argv[2];
	} 
	startup->orix = 0;
	startup->oriy = 0;
	startup->width = WIDTH;
	startup->height = HEIGHT;
	startup->scale = 1.0;
	startup->reload_count = 0;
	startup->serialized = NULL;

	ejoy2d_win_init(startup);

	ShowWindow(wnd, SW_SHOWDEFAULT);
	UpdateWindow(wnd);

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	return 0;
}
