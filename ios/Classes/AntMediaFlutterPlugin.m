#import "AntMediaFlutterPlugin.h"
#if __has_include(<ant_media_flutter/ant_media_flutter-Swift.h>)
#import <ant_media_flutter/ant_media_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ant_media_flutter-Swift.h"
#endif

@implementation AntMediaFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAntMediaFlutterPlugin registerWithRegistrar:registrar];
}
@end
