#include "recognizer_common.h"

float sqr_dist(float x1,float y1,float x2,float y2)
{
	float dx = x1 - x2;
	float dy = y1 - y2;
	return dx * dx + dy * dy;
}
