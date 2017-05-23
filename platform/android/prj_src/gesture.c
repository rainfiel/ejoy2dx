#include "gesture.h"
#include "gesture_recognizer/tap_recognizer.h"
#include "gesture_recognizer/pan_recognizer.h"
#include "gesture_recognizer/press_recognizer.h"
#include "gesture_recognizer/pinch_recognizer.h"

void gr_init() {
  tap_init();
  pan_init();
  press_init();
  pinch_init();
}

void gr_release() {
  tap_release();
  pan_release();
  press_release();
  pinch_release();
}

void gr_touch_begin(int id, float x, float y) {
  tap_touch_begin(id,x,y);
  pan_touch_begin(id,x,y);
  press_touch_begin(id,x,y);  
  pinch_touch_begin(id,x,y);
}

void gr_touch_end(int id, float x, float y, float vx, float vy) {
  tap_touch_end(id,x,y);
  pan_touch_end(id,x,y,vx,vy);
  press_touch_end(id,x,y); 
  pinch_touch_end(id,x,y);
}

void 
gr_touch_move(int size, int* ids, float* xs, float* ys, float vx, float vy) {
  tap_touch_move(size,ids,xs,ys);
  pan_touch_move(size,ids,xs,ys,vx,vy);
  press_touch_move(size,ids,xs,ys);
  pinch_touch_move(size,ids,xs,ys);
}

void 
gr_touch_cancel(int size, int* ids, float* xs, float* ys) {
  tap_touch_cancel(size,ids,xs,ys);
  pan_touch_cancel(size,ids,xs,ys);
  press_touch_cancel(size,ids,xs,ys);
  pinch_touch_cancel(size,ids,xs,ys);
}

void
gr_touch_update() {
    press_touch_update();
}
