//
//  TestCommand.h
//  TestHelper
//
//  Created by Masakiyo on 2015/05/04.
//  Copyright (c) 2015年 Masakiyo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestCommand : NSObject

typedef void (^CallbackFunc)(void);

@property (nonatomic, readonly) NSString *command;
@property (nonatomic, readonly) CallbackFunc callback;

- (instancetype)initWithCommand:(NSString *)command callback:(CallbackFunc)callback;

@end
