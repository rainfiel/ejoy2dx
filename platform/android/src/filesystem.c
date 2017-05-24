#include <stdlib.h>
#include <assert.h>
#include "filesystem.h"

#include <android/log.h>
#define  LOG_TAG    "FS"
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)

struct FileHandle{
  unsigned long size;
  unsigned char* buffer;
  size_t offset;
};

struct FileHandle* pf_fileopen(const char *path, const char* format) {
  unsigned long sz;
  unsigned char* buffer;
  buffer = getFileData(path, format, &sz);
  if(buffer){
    struct FileHandle* ret = malloc(sizeof(*ret));
    ret->buffer = buffer;
    ret->offset = 0;
    ret->size = sz;
    // LOGI("fileopen:%s %d\n", path, sz);
    return ret;
  }else{
    // LOGI("fileopen faild:%s\n", path);
    return NULL;
  }
}

size_t pf_filesize(struct FileHandle* h) {
  return h->size;
}

int pf_fileread(struct FileHandle* h, void *buffer, size_t size) {
  if (size == 0) return 1;
  assert(h->size >= h->offset && h->size > 0 && h->buffer != NULL);
  size_t sz;
  int ret;
  if(h->offset + size <= h->size) {
    sz = size;
    ret = 1;
  } else {
    sz = h->size - h->offset;
    ret = 0;
  }
  if (sz > 0) {
    memcpy(buffer, h->buffer + h->offset, sz);
    h->offset += sz;
  }
  return ret;
}

size_t pf_fread(void *ptr, size_t size, size_t nmemb, struct FileHandle *h) {
  if (nmemb==0) return 0;
  assert(h->size >= h->offset && h->size > 0 && h->buffer != NULL);
  size_t allsize = size * nmemb;
  if(allsize == 0) {
    return 0;
  }

  if(h->offset + allsize <= h->size) {
    memcpy(ptr, h->buffer + h->offset, allsize);
    h->offset += allsize;
    return nmemb;
  }

  unsigned long rest = h->size - h->offset;
  size_t count = (size_t)(rest / size);
  if(count > 0) {
    size_t n = count * size;
    memcpy(ptr, h->buffer + h->offset, n);
    h->offset += n;
  }

  return count;
}

void pf_fileseek_from_cur(struct FileHandle* h, int offset) {
  h->offset += offset;
}

void pf_fileseek_from_head(struct FileHandle* h, int offset) {
  h->offset = offset;
}

void pf_fileclose(struct FileHandle* h) {
  if(h==NULL) return;

  if(h->buffer)
    free(h->buffer);
  free(h);
}

int pf_feof(struct FileHandle* h) {
  return (h->offset >= h->size) ? 1 : 0;
}

struct FileHandle* pf_bundleopen(const char* filename, const char* format){
  return pf_fileopen(filename, format);
}
