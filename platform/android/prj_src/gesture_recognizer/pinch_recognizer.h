#ifndef __PINCH_RECOGNIZER_H
#define __PINCH_RECOGNIZER_H

void pinch_init();
void pinch_release();
void pinch_touch_begin(int id, float x, float y);
void pinch_touch_end(int id, float x, float y);
void pinch_touch_move(int size, int *ids, float *xs, float *ys);
void pinch_touch_cancel(int size, int *ids, float *xs, float *ys);

#endif

