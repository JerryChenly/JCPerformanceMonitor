//
//  JCPerformanceMonitor.m
//  JCPerformanceMonitor
//
//  Created by jerrychen on 2021/11/10.
//

#import "JCPerformanceMonitor.h"
#import <mach/mach.h>


@interface JCPerformanceMonitor()

@property (nonatomic, strong) CADisplayLink *displayLink;

/// 记录当前记录周期内的帧数
@property (nonatomic, assign) int frameCount;

/// 记录fps统计开始时间
@property (nonatomic, assign) NSTimeInterval lastTimeStamp;

@end

@implementation JCPerformanceMonitor

- (instancetype)init {
    if (self = [super init]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

+ (JCPerformanceMonitor *)shared {
    static JCPerformanceMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JCPerformanceMonitor alloc] init];
    });
    return instance;
}

- (void)start {
    [self stop];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fpsCount:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stop {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

#pragma mark - private methods

- (void)receiveNotification:(NSNotification *)notification {
    [self stop];
}

- (void)fpsCount:(CADisplayLink *)dlink {
    if (self.callback == nil){
        // 未设置callback
        return;
    }
    //
    if (self.lastTimeStamp <= 0){
        self.lastTimeStamp = dlink.timestamp;
        return;
    }
    //
    self.frameCount += 1;
    NSTimeInterval useTime = dlink.timestamp - self.lastTimeStamp;
    if (useTime < 1){
        // 时间差小于1s
        return;
    }
    //
    self.lastTimeStamp = dlink.timestamp;
    int fps = self.frameCount / useTime;
    self.frameCount = 0;
    if (self.callback){
        self.callback([self getCpuUsage], [self getMemoryUsage], fps);
    }
}

- (float)getCpuUsage {
    thread_act_array_t threads;
    mach_msg_type_number_t threadCount = 0;
    const task_t thisTask = mach_task_self();
    // 获取当前所有线程
    kern_return_t result = task_threads(thisTask, &threads, &threadCount);
    if (result != KERN_SUCCESS){
        return 0;
    }
    integer_t cpuUsage = 0;
    for (int i = 0; i < threadCount; i++){
        thread_info_data_t threadInfo;
        thread_basic_info_t threadBasicInfo;
        mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
        //
        if (thread_info((thread_act_t)threads[i], THREAD_BASIC_INFO, (thread_info_t)threadInfo, &threadInfoCount) == KERN_SUCCESS){
            // 获取CPU使用率
            threadBasicInfo = (thread_basic_info_t)threadInfo;
            if (!(threadBasicInfo->flags & TH_FLAGS_IDLE)){
                cpuUsage += threadBasicInfo->cpu_usage;
            }
        }
    }
    return cpuUsage/(float)TH_USAGE_SCALE;
}

- (uint64_t)getMemoryUsage {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
    if (result != KERN_SUCCESS){
        return 0;
    }
    return vmInfo.phys_footprint;
}

@end
