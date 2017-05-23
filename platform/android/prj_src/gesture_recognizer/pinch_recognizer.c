#include "pinch_recognizer.h"
#include "recognizer_common.h"

#include "platform_print.h"
#include "framework/fw.h"
#include "math.h"

struct pinch_info {
	int pinch_id;
	float x, y;
};

struct pinch_info pinch_data[2];
static int pinch_index = 0;

static float _distance(float x0, float y0, float x1, float y1)
{
	return sqrt(pow((x0 - x1), 2) + pow((y0 - y1), 2));
}

void pinch_insert(int id, float x, float y)
{
	if (pinch_index == -1) { return ; }

	struct pinch_info *p_data = &pinch_data[pinch_index];
	p_data->pinch_id = id;
	p_data->x = x;
	p_data->y = y;

	pinch_index ^= 1;

	if (pinch_data[pinch_index].pinch_id != -1)
	{
		pinch_index = -1;
	}
}

void pinch_pop(int id)
{
	int i;
	int p_index = -1;
	for (i = 0; i < 2; ++i) {
		if (pinch_data[i].pinch_id == id) {
			p_index = i;
			break;
		}
	}

	if (p_index != -1) {
		pinch_data[p_index].pinch_id = -1;
		pinch_index = p_index;
	}
}

struct pinch_info *get_pinch_data(int id)
{
	int i;
	for (i = 0; i < 2; ++i) {
		if (pinch_data[i].pinch_id == id)
		{
			return &pinch_data[i];
		}
	}

	return 0;
}

void pinch_cancel()
{
	pinch_data[0].pinch_id = pinch_data[1].pinch_id = -1;
	pinch_index = 0;
}

void pinch_update_data(int *ids, float *xs, float *ys)
{
    int i;
    pinch_cancel();
    for (i = 0; i < 2; ++i) {
        pinch_insert(ids[i], xs[i], ys[i]);
    }
}

void pinch_init()
{
	pinch_data[0].pinch_id = -1;
	pinch_data[1].pinch_id = -1;
}

void pinch_release()
{
	pinch_cancel();
}

void pinch_touch_begin(int id, float x, float y)
{
}

void pinch_touch_end(int id, float x, float y)
{
	struct pinch_info *p_data = get_pinch_data(id);
	if (p_data != 0) {
		ejoy2d_fw_gesture(3, 0, 0, 0, 0, STATE_ENDED);
	}
	pinch_cancel();
}

void pinch_touch_move(int size, int *ids, float *xs, float *ys)
{
	if (size != 2) {
		return ;
	}

	int i;
	struct pinch_info *p_data[2];
	for (i = 0; i < 2; ++i) {
		p_data[i] = get_pinch_data(ids[i]);
		if (p_data[i] == 0) {
            pinch_update_data(ids, xs, ys);
			return ;
		}
	}

	float last_dist = _distance(p_data[0]->x, p_data[0]->y, p_data[1]->x, p_data[1]->y);
	float cur_dist = _distance(xs[0], ys[0], xs[1], ys[1]);

	if (cur_dist == 0 || last_dist == 0) {
		pinch_cancel();
		return ;
	}

	float scale = cur_dist / last_dist;
	ejoy2d_fw_gesture(3, (xs[0] + xs[1]) * 0.5f, (ys[0] + ys[1]) * 0.5f, scale, 0, STATE_BEGAN);
    
    pinch_update_data(ids, xs, ys);
}

void pinch_touch_cancel(int size, int *ids, float *xs, float *ys)
{
	pinch_cancel();
}


