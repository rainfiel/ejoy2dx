#ifndef __PRESS_RECOGNIZER_H__
#define __PRESS_RECOGNIZER_H__

void press_init();
void press_release();
void press_touch_begin(int id, float x, float y);
void press_touch_end(int id, float x, float y);
void press_touch_move(int size, int* ids, float* xs, float* ys);
void press_touch_cancel(int size, int* ids, float* xs, float* ys);
void press_touch_update();


#endif
