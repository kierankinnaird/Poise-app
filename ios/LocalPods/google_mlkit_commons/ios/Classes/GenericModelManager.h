#if !TARGET_OS_SIMULATOR
#import <Flutter/Flutter.h>
#import <MLKitCommon/MLKitCommon.h>

@interface GenericModelManager : NSObject
- (void)manageModel:(MLKRemoteModel*)model call:(FlutterMethodCall*)call result:(FlutterResult)result;
@end
#endif
