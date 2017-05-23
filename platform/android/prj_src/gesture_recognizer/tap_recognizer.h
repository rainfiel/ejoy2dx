#ifndef __TAP_RECOGNIZER_H__
#define __TAP_RECOGNIZER_H__

void tap_init();
void tap_release();
void tap_set_num_tapped(int num);
void tap_touch_begin(int id, float x, float y);
void tap_touch_end(int id, float x, float y);
void tap_touch_move(int size, int* ids, float* xs, float* ys);
void tap_touch_cancel(int size, int* ids, float* xs, float* ys);


#endif
