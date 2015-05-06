//
//  TestCommandListener.m
//  TestHelper
//
//  Created by Masakiyo on 2015/05/04.
//  Copyright (c) 2015年 Masakiyo. All rights reserved.
//

#import "TestCommandListener.h"
#import "TestCommand.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

#pragma mark - TestCommandListener private

@interface TestCommandListener ()

@property (nonatomic) short port;
@property (nonatomic) NSMutableDictionary *commands;

- (void)receivedString:(NSString *)string;

@end

#pragma mark - TcpListener

static TestCommandListener *_listener = nil;
static CFStreamClientContext _clientContext = {0, NULL, NULL, NULL, NULL};
static CFReadStreamRef _readStream = NULL;
static unsigned char _readBuffer[1025];
static void handleReadStream(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo);
static void handleConnect(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info);
static void startListening(TestCommandListener *listener);

static CFReadStreamRef createReadStream(CFSocketNativeHandle handle) {
	CFReadStreamRef readStream;
	CFStreamCreatePairWithSocket(kCFAllocatorDefault,
								 handle,
								 &readStream,
								 NULL);
	CFReadStreamSetClient(readStream,
						  kCFStreamEventHasBytesAvailable|kCFStreamEventErrorOccurred|kCFStreamEventEndEncountered,
						  handleReadStream,
						  &_clientContext);
	CFReadStreamScheduleWithRunLoop(readStream,
									CFRunLoopGetMain(),
									kCFRunLoopDefaultMode);
	Boolean open = CFReadStreamOpen(readStream);
	if (open) {
		NSLog(@"TestHelper: Stream opened.");
	} else {
		NSLog(@"TestHelper: Stream open error.");
		CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
		readStream = NULL;
	}
	return readStream;
}

static void destroyReadStream(CFReadStreamRef readStream) {
	NSLog(@"TestHelper: Stream closed.");
	CFReadStreamClose(readStream);
	CFRelease(readStream);
}

static void readData(void) {
	CFIndex num = CFReadStreamRead(_readStream, _readBuffer, sizeof(_readBuffer)-1);
	if (num > 0) {
		*(_readBuffer + num) = '\0';
		NSLog(@"TestHelper: %s", (char *)_readBuffer);
		[_listener receivedString:[NSString stringWithUTF8String:(char *)_readBuffer]];
	} else if (num == 0) {
		NSLog(@"TestHelper: Stream has reached its end.");
	} else {
		NSLog(@"TestHelper: Stream is not open or an error occurs.");
	}
}

static void handleReadStream(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
	switch (eventType) {
		case kCFStreamEventHasBytesAvailable:
			readData();
			break;
		case kCFStreamEventErrorOccurred:
			break;
		case kCFStreamEventEndEncountered:
			destroyReadStream(_readStream);
			_readStream = NULL;
			break;
		default:
			;
	}
}

static void handleConnect(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
	switch (callbackType) {
		case kCFSocketAcceptCallBack:
			if (_readStream == NULL) {
				NSLog(@"TestHelper: Accept");
				_readStream = createReadStream(*((CFSocketNativeHandle *)data));
			} else {
				NSLog(@"TestHelper: Accept");
				destroyReadStream(_readStream);
				_readStream = createReadStream(*((CFSocketNativeHandle *)data));
			}
			break;
		default:
			;
	}
}

static void startListening(TestCommandListener *listener) {
	if (_listener != nil) {
		return;
	}
	_listener = listener;
	NSLog(@"TestHelper: port=%d", listener.port);
	CFSocketRef myipv4cfsock = CFSocketCreate(
											  kCFAllocatorDefault,
											  PF_INET,
											  SOCK_STREAM,
											  IPPROTO_TCP,
											  kCFSocketAcceptCallBack,
											  handleConnect,
											  NULL);
	
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET; /* アドレスファミリ */
	sin.sin_port = htons(listener.port); /* または具体的なポート番号 */
	sin.sin_addr.s_addr= INADDR_ANY;
	CFDataRef sincfd = CFDataCreate(
									kCFAllocatorDefault,
									(UInt8 *)&sin,
									sizeof(sin));
	CFSocketSetAddress(myipv4cfsock, sincfd);
	CFRelease(sincfd);
	
	CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(
																  kCFAllocatorDefault,
																  myipv4cfsock,
																  0);
	CFRunLoopAddSource(
					   CFRunLoopGetMain(),
					   socketsource,
					   kCFRunLoopDefaultMode);
}

#pragma mark - TestCommandListener implementation

@implementation TestCommandListener

- (instancetype)initWithPort:(short)port {
	self = [super init];
	if (self != nil) {
		_port = port;
		_commands = [NSMutableDictionary dictionaryWithCapacity:100];
	}
	return  self;
}

- (void)registCommand:(NSString *)command callback:(void (^)(void))callback {
	TestCommand *tc = [[TestCommand alloc] initWithCommand:command callback:callback];
	[self.commands setObject:tc forKey:command];
}

- (void)startListening {
	startListening(self);
}

- (void)receivedString:(NSString *)string {
	NSError* error = nil;
	NSRegularExpression* regex = nil;
	NSTextCheckingResult *match = nil;
	
	@try {
		regex = [NSRegularExpression regularExpressionWithPattern:@"^[a-zA-Z0-9]+\\s*$"
														  options:NSRegularExpressionCaseInsensitive
															error:&error];
		match = [regex firstMatchInString:string
								  options:0
									range:NSMakeRange(0, string.length)];
		if (match == nil) {
			NSLog(@"TestHelper: \"%@\" : command format error.", string);
			return;
		}
		
		regex = [NSRegularExpression regularExpressionWithPattern:@"^[a-zA-Z0-9]+"
														  options:NSRegularExpressionCaseInsensitive
															error:&error];
		match = [regex firstMatchInString:string
								  options:0
									range:NSMakeRange(0, string.length)];
		
		NSRange range = [match rangeAtIndex:0];
		string = [string substringWithRange:range];
		
		TestCommand *tc = (TestCommand *)[self.commands valueForKey:string];
		
		if (tc == nil) {
			NSLog(@"TestHelper: \"%@\" : command not registered.", string);
			return;
		}
		
		if (tc.callback != nil) {
			tc.callback();
		}
	} @catch (NSException *exception) {
		NSLog(@"TestHelper: \"%@\" : exception.", string);
	} @finally {
	}
}

@end