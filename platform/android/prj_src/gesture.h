#ifndef __GESTURE_ANDROID_H__
#define __GESTURE_ANDROID_H__


void gr_init();
void gr_release();
void gr_touch_begin(int id, float x, float y);
void gr_touch_end(int id, float x, float y, float vx, float vy);
void gr_touch_move(int size, int* ids, float* xs, float* ys, float vx, float vy);
void gr_touch_cancel(int size, int* ids, float* xs, float* ys);
void gr_touch_update();

#endif
