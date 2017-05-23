#include "press_recognizer.h"
#include "recognizer_common.h"
#include "platform_print.h"

#include "framework/fw.h"

#include <stdbool.h>
#include <string.h>
#include <time.h>

#define kPressMinDuration 0.4
#define kTapMaxDistance 100

static float init_x,init_y;
static float cur_x, cur_y;
static int press_id;
static int is_press_start = false;
static clock_t init_time;
static bool is_recognizing = false;

static float CLOCK_TO_SECOND = 1.0f / CLOCKS_PER_SEC;

void press_init()
{
	is_recognizing = false;
    is_press_start = false;
}
void press_release()
{
	is_recognizing = false;
    is_press_start = false;
}

void press_end() 
{
    if (is_press_start) {
        ejoy2d_fw_gesture(4, cur_x, cur_y, 0, 0, STATE_ENDED);
    }

    press_release();
}

void press_touch_begin(int id, float x, float y)
{
	if(id >= 0 ) {
		cur_x = init_x = x;
		cur_y = init_y = y;
		init_time = clock();
		press_id = id;

		is_recognizing = true;
        is_press_start = false;
	}
}
void press_touch_end(int id, float x, float y)
{

	if(is_recognizing) {
        cur_x = x; cur_y = y;
        press_end();
	}
}
void press_touch_move(int size, int* ids, float* xs, float* ys)
{
    if (!is_recognizing) return;

    if (size != 1 || ids[0] != press_id) {
        press_end();
        return ;
    }

    cur_x = xs[0]; cur_y = ys[0];

    if (is_press_start) {
        ejoy2d_fw_gesture(4, cur_x, cur_y, 0, 0, STATE_CHANGED);
    }
}

void press_touch_cancel(int size, int* ids, float* xs, float* ys)
{
    press_end();
}

void press_touch_update()
{
    if (!is_press_start && is_recognizing) {
		float dt = (clock() - init_time) * CLOCK_TO_SECOND;
		float dist = sqr_dist(cur_x, cur_y, init_x, init_y);

		if(dt >= kPressMinDuration && dist < kTapMaxDistance) {
			ejoy2d_fw_gesture(4, cur_x, cur_y, 0, 0, STATE_BEGAN);
            is_press_start = true;
		}
    }
}



