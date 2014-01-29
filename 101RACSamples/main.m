//
//  main.m
//  101RACSamples
//
//  Created by Matthew Doig on 1/26/14.
//  Copyright (c) 2014 DWI. All rights reserved.
//

#pragma mark Asynchronous operations

// Work will start immediately on the background thread
void runAsyncEagerly()
{
    NSLog(@"Shows use of startEagerly on a background thread:");
    
    [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
    }];
    NSLog(@"Main thread completed.");
    [NSThread sleepForTimeInterval:5.0f];
}

// No work will happen. Unlike startEagerly, work will only happen our signal is subscribed to.
void runAsyncLazilyNeverStarts()
{
    NSLog(@"Shows use of startLazily on a background thread:");
    
    [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
    }];
    NSLog(@"Main thread completed.");
    [NSThread sleepForTimeInterval:5.0f];
}

// Work starts when we subscribe to the signal, but the main thread never ends because the background thread never lets the subscriber know it has completed.
void runAsyncLazilyNeverCompletes()
{
    NSLog(@"Shows use of startLazily on a background thread:");
    
    RACSignal *mysignal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
    }];
    NSError *error;
    [mysignal waitUntilCompleted:&error];
    NSLog(@"Main thread completed.");
}

// Work starts and signals the subscriber when it has completed
void runAsyncLazily()
{
    NSLog(@"Shows use of startLazily on a background thread:");
    
    RACSignal *mysignal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        //This starts on a background thread.
        NSLog(@"From background thread. Does not block main thread.");
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
        [subscriber sendCompleted];
    }];
    NSError *error;
    [mysignal waitUntilCompleted:&error];
    NSLog(@"Main thread completed.");
}

void runAsyncFirstSubscriptionOnly() {
    RACSignal *mysignal = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
        [subscriber sendCompleted];
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 1!");
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 2!");
    }];
    NSError *error;
    [mysignal waitUntilCompleted:&error];
    NSLog(@"Main thread completed.");
}

void runAsyncEagerlyDeferred()
{
    NSLog(@"Shows use of startEagerly on a background thread:");
    
    RACSignal *mysignal = [RACSignal defer:^RACSignal *{
        return [RACSignal startEagerlyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
            NSLog(@"Calculating...");
            [NSThread sleepForTimeInterval:3.0f];
            NSLog(@"Background work completed.");
            [subscriber sendCompleted];
        }];
    }];

    [NSThread sleepForTimeInterval:5.0f];

    NSError *error;
    [mysignal waitUntilCompleted:&error];
}

void runAsyncOnDemand() {
    RACSignal *mysignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"Calculating...");
        [NSThread sleepForTimeInterval:3.0f];
        NSLog(@"Background work completed.");
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 1!");
    }];
    [mysignal subscribeCompleted:^{
        NSLog(@"Done 2!");
    }];
    NSLog(@"Main thread completed.");
}

void parallelExecution()
{
    RACSignal *signalA = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Executing first on thread: %@", [NSThread currentThread]);
        [subscriber sendNext:@"ReturnA"];
        [subscriber sendCompleted];
    }];
    
    RACSignal *signalB = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Executing first on thread: %@", [NSThread currentThread]);
        [subscriber sendNext:@"ReturnB"];
        [subscriber sendCompleted];
    }];
    
    RACSignal *signalC = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        NSLog(@"Executing first on thread: %@", [NSThread currentThread]);
        [subscriber sendNext:@"ReturnC"];
        [subscriber sendCompleted];
    }];
    [[RACSignal
        combineLatest:@[signalA, signalB, signalC]
        reduce:^id(NSString *resulta, NSString *resultb, NSString *resultc) {
            NSLog(@"%@", resulta);
            NSLog(@"%@", resultb);
            NSLog(@"%@", resultc);
            return nil;
        }]
        subscribeCompleted:^{
            NSLog(@"Done!");
        }];
    
    NSLog(@"Main thread completed.");
    [NSThread sleepForTimeInterval:5.0f];
}

void cancelAsyncOperation()
{
    RACSignal *mysignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSOperationQueue *op = [[NSOperationQueue alloc] init];
        [op addOperationWithBlock:^{
            int i = 0;
            for (; ; ) {
                [NSThread sleepForTimeInterval:0.2f];
                [subscriber sendNext:[NSNumber numberWithInt:i++]];
            }
        }];
        return [RACDisposable disposableWithBlock:^{
            [op cancelAllOperations];
        }];
    }];
    RACDisposable *subscription = [mysignal subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [NSThread sleepForTimeInterval:5.0f];
    [subscription dispose];
    [NSThread sleepForTimeInterval:3.0f];
    NSLog(@"Main thread completed.");
}

#pragma mark Creation operators

void simpleReturn()
{
    RACSignal *oneNumber = [RACSignal return:@1];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [oneNumber
        subscribeCompleted:^{
            NSLog(@"Done!");
        }];
    [oneNumber
        subscribeError:^(NSError *error) {
            NSLog(@"%@", error);
        }];
}

void simpleEmpty()
{
    RACSignal *oneNumber = [RACSignal empty];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [oneNumber
        subscribeCompleted:^{
            NSLog(@"Done!");
        }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

void simpleNever()
{
    RACSignal *oneNumber = [RACSignal never];
    [oneNumber
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [oneNumber
     subscribeCompleted:^{
         NSLog(@"Done!");
     }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

void simpleError()
{
    RACSignal *oneNumber = [RACSignal error:[NSError errorWithDomain:@"Domain" code:1 userInfo:@{}]];
    [oneNumber
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [oneNumber
     subscribeCompleted:^{
         NSLog(@"Done!");
     }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

void simpleCreate()
{
    RACSignal *oneNumber = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"Disposed");
        }];
    }];
    [oneNumber
     subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [oneNumber
     subscribeCompleted:^{
         NSLog(@"Done!");
     }];
    [oneNumber
     subscribeError:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}

#pragma mark Restriction operators

void simpleFilter()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        filter:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleDistinctUntilChanged()
{
    RACSignal *sameNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           return running;
        }]
        distinctUntilChanged];
    
    [sameNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}


void simpleIgnore()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        ignore:@5];
    
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleIgnoreValues()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        ignoreValues];
    
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTake()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        take:4]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTakeWhile()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        takeWhileBlock:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTakeUntil()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        takeUntilBlock:^BOOL(NSNumber *value) {
            return [value intValue] > 4;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTakeLast()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[[oneNumberEverySecond
        take:4]
        takeLast:2]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleSkip()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        skip:4]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleSkipWhile()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        skipWhileBlock:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleSkipUntil()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        skipUntilBlock:^BOOL(NSNumber *value) {
            return [value intValue] > 4;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Inspection Operators

void simpleAny()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        any:^BOOL(NSNumber *value) {
            return [value intValue] > 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleAll()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@4];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        all:^BOOL(NSNumber *value) {
            return [value intValue] < 5;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Aggregation Operators

void simpleAggregationWithStart()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@4];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        aggregateWithStart:@0 reduce:^id(id running, id next) {
            int i = [running intValue] + [next intValue];
            return [NSNumber numberWithInt:i];
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleFirst()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@4];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    NSLog(@"%@", [firstFourNumbers first]);
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleFirstOrDefault()
{
    RACSignal *empty = [RACSignal empty];
    NSLog(@"%@", [empty firstOrDefault:nil]);
}

void simpleCollect()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        take:3];
    [[oneNumberEverySecond
        collect]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Error Handling Operators

void simpleCatch()
{
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        catch:^RACSignal *(NSError *error) {
            NSLog(@"Swallowed!");
            return [RACSignal empty];
        }];
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleCatchTo()
{
    RACSignal *errors = [RACSignal return:@1];
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        catchTo:errors];
                            
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [error
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleFinally()
{
    RACSignal *oneNumber = [[RACSignal
        return:@1]
        finally:^{
            NSLog(@"Finally!");
        }];
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        finally:^{
            NSLog(@"Finally!");
        }];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
    ];
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleInitially()
{
    RACSignal *oneNumber = [[RACSignal
        return:@1]
        initially:^{
            NSLog(@"Initially!");
        }];
    
    RACSignal *error = [[RACSignal
        error:[NSError errorWithDomain:@"domain" code:1 userInfo:@{}]]
        initially:^{
            NSLog(@"Initially!");
        }];
    [oneNumber
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [error
        subscribeError:^(id x) {
            NSLog(@"%@", x);
        }
     ];
}

void simpleTry()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@5];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        try:^BOOL(NSNumber *value, NSError *__autoreleasing *errorPtr) {
            if ([value intValue]  > 4) return NO;
            return YES;
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleTryMap()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@5];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        tryMap:^id(NSNumber *value, NSError *__autoreleasing *errorPtr) {
            int i = [value intValue];
            if (i > 4) return nil;
            return [NSNumber numberWithInt:i*i];
        }]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Projection Operators

void simpleMap()
{
    NSDate *start = [NSDate date];
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        map:^id(NSDate *value) {
            NSTimeInterval interval = [value timeIntervalSinceDate:start];
            return [NSNumber numberWithInt:(int)interval];
        }];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleScan()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleScanAndMap()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:[RACTuple tupleWithObjects:@0, [NSDate date], nil] reduce:^id(RACTuple *running, id next) {
           NSDate *start = [running second];
           NSTimeInterval interval = [next timeIntervalSinceDate:start];
           return [RACTuple tupleWithObjects:[NSNumber numberWithInt:(int)interval], start, nil];
        }]
        map:^id(RACTuple *value) {
            return [value first];
        }];
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:10.0f];
}

#pragma mark Partioning Operators

void simpleGroupBy()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        map:^id(NSNumber *value) {
            NSString *oddOrEven = [value intValue] % 2 == 0 ? @"EVEN" : @"ODD";
            return [RACTuple tupleWithObjects:oddOrEven, value, nil];
        }];;
    
    [[oneNumberEverySecond
        groupBy:^id<NSCopying>(RACTuple *tuple) {
            return tuple.first;
        }]
        subscribeNext:^(RACGroupedSignal *x) {
            __block int numItems = 0;
            
            [x subscribeNext:^(RACTuple *x) {
                NSLog(@"There are %d in the %@ group", ++numItems, [x first]);
            }];
        }];
    [NSThread sleepForTimeInterval:21.0f];
}

#pragma mark Time Related Operators

void simpleBufferWithTime()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    [[oneNumberEverySecond
        bufferWithTime:5.0f onScheduler:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleDelay()
{
    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    //Instant Echo
    [oneNumberEveryFiveSeconds
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    //One second delay
    [[oneNumberEveryFiveSeconds
        delay:1.0f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    //Two second delay
    [[oneNumberEveryFiveSeconds
        delay:2.0f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }
     ];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleInterval()
{
    RACSignal *oneDateEverySecond = [RACSignal interval:1.0f onScheduler:[RACScheduler scheduler]];
    [oneDateEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleSample()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    RACSignal *oneDateEveryFiveSeconds = [RACSignal interval:5.0f onScheduler:[RACScheduler scheduler]];
    [[oneNumberEverySecond
        sample:oneDateEveryFiveSeconds]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleThrottle()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    
    RACSignal *oneDateEveryTwoSeconds = [RACSignal interval:2.0f onScheduler:[RACScheduler scheduler]];

    [[oneNumberEverySecond
        throttle:1.1f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [[oneDateEveryTwoSeconds
        throttle:1.1f]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleWaitUnitlCompleted()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@2];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@3];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendNext:@5];
        [NSThread sleepForTimeInterval:1.0f];
        [subscriber sendCompleted];
    }];
    NSError *error;
    [firstFourNumbers waitUntilCompleted:&error];
    
    NSLog(@"End main thread");
}

#pragma mark Combination Operators

void simpleMerge()
{
    RACSignal *oneDateEverySecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];

    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];

    [[RACSignal
        merge:@[oneDateEverySecond, oneNumberEveryFiveSeconds]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleSwitch()
{
    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    
    RACSignal *number1EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@1 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    RACSignal *number2EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@2 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    RACSignal *number3EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@3 reduce:^id(NSNumber *running, id next) {
           return running;
        }];

    [[RACSignal
         switch:oneNumberEveryFiveSeconds cases:@{@1: number1EverySecond, @2: number2EverySecond, @3: number3EverySecond} default:[RACSignal empty]]
         subscribeNext:^(id x) {
            NSLog(@"%@", x);
         }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleIfThenElse()
{
    RACSignal *oneBoolEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
            return [running intValue] % 2 == 0 ? @YES : @NO;
        }];
    
    RACSignal *number1EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@1 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    RACSignal *number2EverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@2 reduce:^id(NSNumber *running, id next) {
           return running;
        }];
    
    [[RACSignal
         if:oneBoolEveryFiveSeconds then:number1EverySecond else:number2EverySecond]
         subscribeNext:^(id x) {
            NSLog(@"%@", x);
         }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleZip()
{
    RACSignal *oneDateEverySecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];

    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];

    [[RACSignal
        zip:@[oneDateEverySecond, oneNumberEveryFiveSeconds]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleCombineLatest()
{
    RACSignal *oneDateEverySecond = [RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]];

    RACSignal *oneNumberEveryFiveSeconds = [[RACSignal
        interval:5.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    
    [[RACSignal
        combineLatest:@[oneDateEverySecond, oneNumberEveryFiveSeconds]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleConcat()
{
    RACSignal *oneDateEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        take:3];

    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        take:3];
    
    [[RACSignal
        concat:@[oneDateEverySecond, oneNumberEverySecond]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:21.0f];
}

void simpleConcatHot()
{
    RACSignal *oneDateEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        take:3];

    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        take:5];
    
    RACMulticastConnection *shared = [oneNumberEverySecond publish];
    [shared connect];
    RACSignal *oneNumberEverySecondHot = [shared signal];
    
    [[RACSignal
        concat:@[oneDateEverySecond, oneNumberEverySecondHot]]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleThen()
{
    RACSignal *oneDateEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        take:3];

    RACSignal *oneNumberEverySecond = [[[[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        take:3]
        doNext:^(id x) {
            NSLog(@"%@", x);
        }]
        then:^RACSignal *{
            return oneDateEverySecond;
        }];
    
    [oneNumberEverySecond
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:10.0f];
}


void simpleRepeat()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendNext:@4];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        repeat]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleStartWith()
{
    RACSignal *firstFourNumbers = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        [subscriber sendNext:@3];
        [subscriber sendNext:@4];
        [subscriber sendCompleted];
    }];
    [[firstFourNumbers
        startWith:@0]
        subscribeNext:^(id x) {
            NSLog(@"%@", x);
        }];
}

#pragma mark Sharing Operators

void simplePublish()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];
    
    // Each subscription starts a new sequence
    RACDisposable *sub1 = [oneNumberEverySecond subscribeNext:^(id x) {
         NSLog(@"%@", x);
     }];
    [NSThread sleepForTimeInterval:5.0f];
    RACDisposable *sub2 = [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    [sub1 dispose];
    [sub2 dispose];
    
    RACSignal *oneNumberEverySecondShared = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];

    RACMulticastConnection *shared = [oneNumberEverySecondShared publish];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [NSThread sleepForTimeInterval:5.0f];
    [shared connect];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:10.0f];
}

void simpleMulticastReplay()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];

    RACMulticastConnection *shared = [oneNumberEverySecond multicast:[RACReplaySubject subject]];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [shared connect];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleMulticastBehavior()
{
    RACSignal *oneNumberEverySecond = [[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }];

    RACMulticastConnection *shared = [oneNumberEverySecond multicast:[RACBehaviorSubject subject]];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [shared connect];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [[shared signal] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleReplay()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        replay];

    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleReplayLast()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        replayLast];

    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

void simpleReplayLazily()
{
    RACSignal *oneNumberEverySecond = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        replay];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    RACDisposable *sub1 = [oneNumberEverySecond subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
    [sub1 dispose];
    
    RACSignal *oneNumberEverySecondLazy = [[[RACSignal
        interval:1.0f
        onScheduler:[RACScheduler scheduler]]
        scanWithStart:@0 reduce:^id(NSNumber *running, id next) {
           int i = [running intValue];
           return [NSNumber numberWithInt:++i];
        }]
        replayLazily];
    
    [NSThread sleepForTimeInterval:5.0f];
    
    [oneNumberEverySecondLazy subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    
    [NSThread sleepForTimeInterval:5.0f];
}

#pragma mark Main

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        simpleCollect();
    }
    return 0;
}
