#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
int
arasan_init();

#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
int
arasan_main();

#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
ssize_t
arasan_stdin_write(char *data);

#ifdef __cplusplus
extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif
char *
arasan_stdout_read();
