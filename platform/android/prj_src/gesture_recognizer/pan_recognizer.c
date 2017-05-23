#include "pan_recognizer.h"
#include "recognizer_common.h"
#include "platform_print.h"

#include "framework/fw.h"

#include <stdbool.h>
#include <time.h>


static float init_x,init_y;
static clock_t init_time;
static int pan_id;
static bool is_recognizing = false;
static bool never_reported = true;

#include <android/log.h>
#include <jni.h>

void pan_init()
{
	is_recognizing = false;
    pan_id = -1;
}
void pan_release()
{
	is_recognizing = false;
	never_reported = true;
    pan_id = -1;
}

void pan_touch_begin(int id, float x, float y)
{
	if(id >= 0 )
	{
		init_x = x;
		init_y = y;
		pan_id = id;
		init_time = clock();
	}
}
void pan_touch_end(int id, float x, float y, float vx, float vy)
{
	if(id == pan_id && is_recognizing)
	{
		ejoy2d_fw_gesture(1, x, y, vx, vy, STATE_ENDED);
		never_reported = true;
		is_recognizing = false;
	}
}
void pan_touch_move(int size, int* ids, float* xs, float* ys, float vx, float vy)
{
    if (size != 1) {
        pan_touch_cancel(size, ids, xs, ys);
        return ;
    }

    if (ids[0] == pan_id)
    {	float dx = xs[0] - init_x;
        float dy = ys[0] - init_y;
        if(dx * dx + dy * dy > 100.0f)
        {
            if(!is_recognizing)
            {
                is_recognizing = true;
                never_reported = true;						
            }
            int state = STATE_CHANGED;
            if(never_reported)
            {
                state = STATE_BEGAN;
                never_reported = false;					
            }

            ejoy2d_fw_gesture(1, dx,dy,vx,vy,state);
            init_x = xs[0];
            init_y = ys[0];
            init_time = clock();
        }
    }			
}
void pan_touch_cancel(int size, int* ids, float* xs, float* ys)
{
	if(is_recognizing)
	{
		int i =0;
		for(i =0; i < size;++i)
		{
			if (ids[i] == pan_id)
			{
				ejoy2d_fw_gesture(1, 0,0,0,0,STATE_CANCELLED);
			}			
		}
		never_reported = true;
		is_recognizing = false;		
        pan_id = -1;
	}
}
