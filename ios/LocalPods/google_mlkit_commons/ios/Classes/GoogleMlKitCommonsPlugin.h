#import <Flutter/Flutter.h>
#if !TARGET_OS_SIMULATOR
#import <MLKitVision/MLKitVision.h>
#import "GenericModelManager.h"
#endif

@interface GoogleMlKitCommonsPlugin : NSObject<FlutterPlugin>
@end

#if !TARGET_OS_SIMULATOR
@interface MLKVisionImage(FlutterPlugin)
+ (MLKVisionImage *)visionImageFromData:(NSDictionary *)imageData;
@end
#endif

static FlutterError *getFlutterError(NSError *error) {
    return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %d", (int)error.code]
                               message:error.domain
                               details:error.localizedDescription];
}
