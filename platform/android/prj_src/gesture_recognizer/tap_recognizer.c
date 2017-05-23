#include "tap_recognizer.h"
#include "recognizer_common.h"

#include "framework/fw.h"

#include <stdbool.h>
#include <string.h>
#include <time.h>

#include <android/log.h>
#include <jni.h>

#define kTapMaxDuration 0.3
#define kTapMaxDurationBetweenTaps 0.5
#define kTapMaxDistance 100
#define kTapMaxDistanceBetweenTaps 100

static float tap_x,tap_y;
static float init_x,init_y;
static float end_x,end_y;
static int tap_id;
static taps = 0;
static clock_t init_time;
static clock_t end_time;
static bool is_recognizing = false;

static int num_tap_required = 1;

static float CLOCK_TO_SECOND = 1.0f / CLOCKS_PER_SEC;


void tap_init()
{
	tap_x = 0.0f;
	tap_y = 0.0f;
	taps = 0;
	is_recognizing = false;
	num_tap_required = 1;
}
void tap_release()
{
	is_recognizing = false;
}

void tap_set_num_tapped(int num)
{
	num_tap_required = num;
}
void tap_touch_begin(int id, float x, float y)
{
	is_recognizing = false;
	if(id >= 0)
	{
		init_x = x;
		init_y = y;
		init_time = clock();
		tap_id = id;

		is_recognizing = true;
		
		if(taps > 0 && taps < num_tap_required)
		{
			float dist = sqr_dist(end_x,end_y,init_x,init_y);
			clock_t dt = (init_time - end_time) * CLOCK_TO_SECOND;
			is_recognizing = (dist < kTapMaxDistanceBetweenTaps &&
								dt < kTapMaxDurationBetweenTaps); 
		}	
	}
}
void tap_touch_end(int id, float x, float y)
{
	if(id == tap_id && is_recognizing)
	{
		end_x = x;
		end_y = y;
		end_time = clock();
		float dist = sqr_dist(end_x,end_y,init_x,init_y);
		clock_t dt = (end_time - init_time) * CLOCK_TO_SECOND;
		if (dt <=kTapMaxDuration && dist<= kTapMaxDistance)
		{
			taps++;
			//  ��ュ�� tap
			if(taps>= num_tap_required)
			{
				//__android_log_print(ANDROID_LOG_DEBUG,"GESTURE","TAP,%f,%f",x,y);
				ejoy2d_fw_gesture(2,end_x,end_y,0,0,0);
				taps = 0;
				is_recognizing = false;	
			}
		
		}
		else
		{
			is_recognizing = false;			
		}

			
	}
}
void tap_touch_move(int size, int* ids, float* xs, float* ys){}

void tap_touch_cancel(int size, int* ids, float* xs, float* ys) 
{
    tap_release();
}
