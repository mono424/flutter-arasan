#import "ArasanPlugin.h"
#import "ffi.h"

@implementation ArasanPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  if (registrar == NULL) {
    // avoid dead code stripping
    arasan_init();
    arasan_main();
    arasan_stdin_write(NULL);
    arasan_stdout_read();
  }
}

@end
