#ifndef __PAN_RECOGNIZER_H__
#define __PAN_RECOGNIZER_H__

void pan_init();
void pan_release();
void pan_touch_begin(int id, float x, float y);
void pan_touch_end(int id, float x, float y, float vx, float vy);
void pan_touch_move(int size, int* ids, float* xs, float* ys, float vx, float vy);
void pan_touch_cancel(int size, int* ids, float* xs, float* ys);


#endif
