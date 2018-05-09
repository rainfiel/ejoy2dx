#ifndef __EJ_MD5_H__
#define __EJ_MD5_H__

#include <stddef.h>

void md5_signature_byte(const char * text, size_t sz, size_t sig[4]);
void md5_signature(const char * text, size_t sz, char sig[32]);
void md5_signature_header(const char * text, size_t sz, const char * header, size_t hsz, char sig[32]);

int md5_file(const char* filename, char sig[32]);

#endif
