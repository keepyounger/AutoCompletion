//
//  AppDelegate.m
//  AutoCompletion
//
//  Created by 李向阳 on 2016/10/24.
//  Copyright © 2016年 ifang. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self moveDefaultGetters];
}

- (void)moveDefaultGetters
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Containers/com.ifang.AutoCompletion.AutoCompletionExtension/Data/Documents/AutoCompletion/DefaultGetters.plist"];
    if (![manager fileExistsAtPath:path]) {
        
        NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Containers/com.ifang.AutoCompletion.AutoCompletionExtension/Data/Documents/AutoCompletion"];
        [manager createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:nil];
        
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultGetters" ofType:@"plist"]];
        [dic writeToFile:path atomically:YES];
    }
}


- (IBAction)helpClick:(NSMenuItem *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/keepyounger/AutoCompletion"]];
}

- (IBAction)customRulesClick:(NSButton *)sender
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Containers/com.ifang.AutoCompletion.AutoCompletionExtension/Data/Documents/AutoCompletion/DefaultGetters.plist"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
