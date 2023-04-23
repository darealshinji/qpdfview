/**
 * Copyright (C) 2023 djcj@gmx.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


inline long get_long(const char *str)
{
  int base = 10;

  if (strncmp(str, "0x", 2) == 0) {
    base = 16;
  }

  return strtol(str, NULL, base);
}

int read_data(const char *arg_offset, const char *arg_length, const char *file)
{
  FILE *fp = fopen(file, "rb");

  if (!fp) {
    perror("fopen()");
    return 1;
  }

  fseek(fp, 0, SEEK_END);
  long fsize = ftell(fp);
  long offset = get_long(arg_offset);

  if (offset >= fsize) {
    fprintf(stderr, "error: offset %s filesize\n", (offset == fsize) ? "equals" : "exceeds");
    fclose(fp);
    return 1;
  }

  if (fseek(fp, offset, SEEK_SET) == -1) {
    perror("fseek()");
    fclose(fp);
    return 1;
  }

  long len = get_long(arg_length);
  int n = 1;

  if (len < 1) {
    fseek(fp, 0, SEEK_END);
    len = ftell(fp) - offset;
    fseek(fp, offset, SEEK_SET);
  }

  for (long i=0; i < len; i++, n++) {
    int c = fgetc(fp);

    if (c == EOF) {
      putchar('\n');
      break;
    }

    printf(" %02X", (unsigned char)c);

    if ((i+1) == len || (i > 0 && (i+1) % 16 == 0)) {
      putchar('\n');
      n = 1;
    } else if (n == 8) {
      printf("   ");
    }
  }

  fclose(fp);
  return 0;
}

int write_to_file(const char *file, unsigned char *data, long offset, long num_bytes)
{
  int fd = open(file, O_RDWR | O_CREAT, 0664);

  if (fd == -1) {
    perror("creat()");
    return 1;
  }

  if (lseek(fd, offset, SEEK_SET) == -1) {
    perror("lseek()");
    close(fd);
    return 1;
  }

  if (write(fd, data, num_bytes) != num_bytes) {
    perror("write()");
    close(fd);
    return 1;
  }

  close(fd);

  printf("Bytes successfully written to `%s'\n", file);

  return 0;
}

int write_data(const char *arg_offset, const char *arg_data, const char *file)
{
  if (*arg_data == 0) {
    fprintf(stderr, "error: empty argument\n");
    return 1;
  }

  long len = strlen(arg_data);
  char *copy = malloc(len + 2);
  char *p = copy;

  for (long i=0; i < len; i++) {
    if (isspace(arg_data[i])) continue;

    if (!isxdigit(arg_data[i])) {
      fprintf(stderr, "error: argument must contain only hexadecimal digits\n");
      free(copy);
      return 1;
    }

    *p++ = arg_data[i];
  }

  *p = 0;
  len = strlen(copy);

  unsigned char *arr = malloc(len + 2);
  unsigned char *p2 = arr;
  size_t num_bytes = 0;

  if (len % 2 != 0) {
    copy[len] = copy[len-1];
    copy[len-1] = '0';
    copy[len+1] = 0;
  }

  for (long i=0; i < strlen(copy); i += 2) {
    char tmp[5] = { '0','x',0,0,0 };
    tmp[2] = copy[i];
    tmp[3] = copy[i+1];
    *p2++ = (unsigned char)strtol(tmp, NULL, 16);
    num_bytes++;
  }

  free(copy);

  int rv = write_to_file(file, arr, get_long(arg_offset), num_bytes);
  free(arr);

  return rv;
}

int memset_write_data(const char *arg_offset, const char *arg_length, const char *arg_char, const char *file)
{
  long len = get_long(arg_length);
  long chrlen = strlen(arg_char);
  unsigned char *data = NULL;
  unsigned char c = 0;

#define ERR_INVARG \
  fprintf(stderr, "error: invalid argument: %s\n", arg_char); \
  return 1

  if (chrlen == 1) {
    /* literal character */
    c = (unsigned char)arg_char[0];
  } else if (chrlen > 2 && strncmp(arg_char, "0x", 2) == 0) {
    /* hex number */
    char *endptr = NULL;
    errno = 0;
    long l = strtol(arg_char, &endptr, 16);

    if (errno != 0 || *endptr != '\0' || l < 0 || l > 255) {
      ERR_INVARG;
    }

    c = (unsigned char)l;
  } else if (chrlen > 1 && arg_char[0] == '\\') {
    /* escaped decimal number */
    char *endptr = NULL;
    errno = 0;
    long l = strtol(arg_char + 1, &endptr, 10);

    if (errno != 0 || *endptr != '\0' || l < 0 || l > 255) {
      ERR_INVARG;
    }

    c = (unsigned char)l;
  } else {
    ERR_INVARG;
  }

  data = malloc(len);
  memset(data, c, len);

  int rv = write_to_file(file, data, get_long(arg_offset), len);
  free(data);

  return rv;
}

void show_help(const char *self)
{
  printf("usage:\n"
         "  %s --help\n", self);
  printf("  %s read <offset> <length> <file>\n", self);
  printf("  %s write <offset> <data> <file>\n", self);
  printf("  %s memset <offset> <length> <char> <file>\n"
         "\n", self);
  printf("  Offset and length may be hexadecimal prefixed with `0x' or decimal.\n"
         "  Data must be hexadecimal without prefixes.\n"
         "  Char can be a literal character, a hexadecimal value prefixed with `0x'\n"
         "  or a decimal number prefixed with `\\'.\n");
}

int main(int argc, char **argv)
{
  for (int i=0; i < argc; i++) {
    if (strcmp(argv[i], "--help") == 0) {
      show_help(argv[0]);
      return 0;
    }
  }

  if (argc == 5 && strcmp(argv[1], "read") == 0) {
    return read_data(argv[2], argv[3], argv[4]);
  } else if (argc == 5 && strcmp(argv[1], "write") == 0) {
    return write_data(argv[2], argv[3], argv[4]);
  } else if (argc == 6 && strcmp(argv[1], "memset") == 0) {
    return memset_write_data(argv[2], argv[3], argv[4], argv[5]);
  }

  show_help(argv[0]);

  return 1;
}


