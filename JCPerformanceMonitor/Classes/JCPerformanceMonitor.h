//
//  JCPerformanceMonitor.h
//  JCPerformanceMonitor
//
//  Created by jerrychen on 2021/11/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 监控数据回调(cpu使用量，内存使用量，FPS)
typedef void(^JCPerformanceMonitorCallback)(float, uint64_t, int);

@interface JCPerformanceMonitor : NSObject

/// 尽量保持一秒钟回调一次， 但是回调周期不可靠
@property (nonatomic, copy) JCPerformanceMonitorCallback callback;

+ (JCPerformanceMonitor *)shared;

/// 开启监控
- (void)start;

/// 停止监控
- (void)stop;

@end

NS_ASSUME_NONNULL_END
