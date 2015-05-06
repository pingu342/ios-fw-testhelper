//
//  TestCommand.m
//  TestHelper
//
//  Created by Masakiyo on 2015/05/04.
//  Copyright (c) 2015年 Masakiyo. All rights reserved.
//

#import "TestCommand.h"

@interface TestCommand ()

@property (nonatomic) NSString *command;
@property (nonatomic) CallbackFunc callback;

@end

@implementation TestCommand

- (instancetype)initWithCommand:(NSString *)command callback:(CallbackFunc)callback {
	self = [super init];
	if (self != nil) {
		_command = command;
		_callback = callback;
	}
	return self;
}

@end
