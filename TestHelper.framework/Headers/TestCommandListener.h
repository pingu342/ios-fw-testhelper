//
//  TestCommandListener.h
//  TestHelper
//
//  Created by Masakiyo on 2015/05/04.
//  Copyright (c) 2015年 Masakiyo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestCommandListener : NSObject

@property (nonatomic, readonly) short port;

- (instancetype)initWithPort:(short)port;

- (void)registCommand:(NSString *)command callback:(void (^)(void))callback;

- (void)startListening;

@end
