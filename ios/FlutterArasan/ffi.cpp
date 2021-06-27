#include <iostream>
#include <stdio.h>
#include <unistd.h>

#include "../Arasan/src/bitboard.h"
#include "../Arasan/src/search.h"

// #include "../Arasan/src/attacks.h"
// #include "../Arasan/src/bookread.h"
// #include "../Arasan/src/ecodata.h"
// #include "../Arasan/src/material.h"
// #include "../Arasan/src/search.h"
// #include "../Arasan/src/threadc.h"
// #include "../Arasan/src/bench.h"
// #include "../Arasan/src/bookwrit.h"
// #include "../Arasan/src/ecoinfo.h"
// #include "../Arasan/src/movearr.h"
// #include "../Arasan/src/searchc.h"
// #include "../Arasan/src/threadp.h"
// #include "../Arasan/src/bhash.h"
// #include "../Arasan/src/calctime.h"
// #include "../Arasan/src/epdrec.h"
// #include "../Arasan/src/movegen.h"
// #include "../Arasan/src/see.h"
// #include "../Arasan/src/topo.h"
// #include "../Arasan/src/bitboard.h"
// #include "../Arasan/src/chess.h"
// #include "../Arasan/src/globals.h"
// #include "../Arasan/src/notation.h"
// #include "../Arasan/src/stats.h"
// #include "../Arasan/src/tune.h"
// #include "../Arasan/src/bitprobe.h"
// #include "../Arasan/src/chessio.h"
// #include "../Arasan/src/hash.h"
// #include "../Arasan/src/options.h"
// #include "../Arasan/src/stdendian.h"
// #include "../Arasan/src/types.h"
// #include "../Arasan/src/board.h"
// #include "../Arasan/src/constant.h"
// #include "../Arasan/src/learn.h"
// #include "../Arasan/src/params.h"
// #include "../Arasan/src/syzygy.h"
// #include "../Arasan/src/unit.h"
// #include "../Arasan/src/boardio.h"
// #include "../Arasan/src/debug.h"
// #include "../Arasan/src/legal.h"
// #include "../Arasan/src/protocol.h"
// #include "../Arasan/src/tbconfig.h"
// #include "../Arasan/src/bookdefs.h"
// #include "../Arasan/src/eco.h"
// #include "../Arasan/src/log.h"
// #include "../Arasan/src/scoring.h"
// #include "../Arasan/src/tester.h"

#include "ffi.h"

// https://jineshkj.wordpress.com/2006/12/22/how-to-capture-stdin-stdout-and-stderr-of-child-program/
#define NUM_PIPES 2
#define PARENT_WRITE_PIPE 0
#define PARENT_READ_PIPE 1
#define READ_FD 0
#define WRITE_FD 1
#define PARENT_READ_FD (pipes[PARENT_READ_PIPE][READ_FD])
#define PARENT_WRITE_FD (pipes[PARENT_WRITE_PIPE][WRITE_FD])
#define CHILD_READ_FD (pipes[PARENT_WRITE_PIPE][READ_FD])
#define CHILD_WRITE_FD (pipes[PARENT_READ_PIPE][WRITE_FD])

int main(int, char **);

const char *QUITOK = "quitok\n";
int pipes[NUM_PIPES][2];
char buffer[80];

int arasan_init()
{
  pipe(pipes[PARENT_READ_PIPE]);
  pipe(pipes[PARENT_WRITE_PIPE]);

  return 0;
}

int arasan_main()
{
  dup2(CHILD_READ_FD, STDIN_FILENO);
  dup2(CHILD_WRITE_FD, STDOUT_FILENO);

  int argc = 1;
  char *argv[] = {""};
  int exitCode = main(argc, argv);

  std::cout << QUITOK << std::flush;

  return exitCode;
}

ssize_t arasan_stdin_write(char *data)
{
  return write(PARENT_WRITE_FD, data, strlen(data));
}

char *arasan_stdout_read()
{
  ssize_t count = read(PARENT_READ_FD, buffer, sizeof(buffer) - 1);
  if (count < 0)
  {
    return NULL;
  }

  buffer[count] = 0;
  if (strcmp(buffer, QUITOK) == 0)
  {
    return NULL;
  }

  return buffer;
}
