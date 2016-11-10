//
//  SourceEditorCommand.m
//  AutoCompletionExtension
//
//  Created by 李向阳 on 2016/10/24.
//  Copyright © 2016年 ifang. All rights reserved.
//

#import "SourceEditorCommand.h"

@interface SourceEditorCommand ()
@property (nonatomic, strong) XCSourceTextBuffer *buffer;
@property (nonatomic, strong) NSDictionary *gettersInfo;
@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    self.buffer = invocation.buffer;
    [self checkAndComletionGetterWithCurrentLine:self.buffer.selections.firstObject.start.line];
    completionHandler(nil);
}

- (NSDictionary *)gettersInfo
{
    if (!_gettersInfo) {
        
        NSString *home = NSHomeDirectory();
        NSString *path = [home stringByAppendingPathComponent:@"Documents/AutoCompletion/DefaultGetters.plist"];
        _gettersInfo = [NSDictionary dictionaryWithContentsOfFile:path];

        if (!_gettersInfo) {
            _gettersInfo = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultGetters" ofType:@"plist"]];
        }
        
    }
    return _gettersInfo;
}

- (NSArray *)extractingFromString:(NSString *)str regexPattern:(NSString *)regex
{
    NSError *error=nil;
    NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:&error];
    if (error) {
        NSLog(@"Error creating Regex: %@",[error description]);
        return nil;
    }
    
    __block NSMutableArray *retVal = [NSMutableArray array];
    [pattern enumerateMatchesInString:str options:0 range:NSMakeRange(0, [str length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        //Note, we only want to return the things in parens, so we're skipping index 0 intentionally
        for (int i=1; i<[result numberOfRanges]; i++) {
            NSString *matchedString=[str substringWithRange:[result rangeAtIndex:i]];
            [retVal addObject:matchedString];
        }
    }];
    return retVal;
}

- (void)checkAndComletionGetterWithCurrentLine:(NSInteger)lineNum
{
    NSString *currentLine = self.buffer.lines[lineNum];
    //get the return type of getter
    NSArray *array = [self extractingFromString:currentLine regexPattern:@"\\(\\s*(\\w+\\s*\\*?)\\s*\\)"];
    if (array.count<=0) {
        return;
    }
    NSString *type = [array[0] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //get the name of getter
    array = [self extractingFromString:currentLine regexPattern:@"\\)\\s*(\\w+)\\s*\\n$"];
    if (array.count<=0) {
        return;
    }
    NSString *name = array[0];
    
    NSLog(@"%@,%@",type,name);
    
    //根据type找到对应的替换文本
    NSString *replaceContent =  nil;
    
    NSString * const defaultReplaceGetterOfScalar = @"{\n\t<#custom#>\n}\n";
    
    NSString * replaceGetter = nil;
    @synchronized(self.gettersInfo){ //简单同步
        replaceGetter = self.gettersInfo[type];
    }
    if (replaceGetter) {
        replaceContent =  [replaceGetter stringByReplacingOccurrencesOfString:@"<name>" withString:name];
    }else{
        NSString *replaceGetter = defaultReplaceGetterOfScalar;
        if ([type hasSuffix:@"*"]||[type isEqualToString:@"id"]) {
            NSString * const defaultReplaceGetterOfPointer = @"{\n\tif (!_<name>) {%@\n\t\t<#custom#>\n\t}\n\treturn _<name>;\n}\n";
            NSString *otherContent = @"";
            if ([type hasSuffix:@"*"]) {
                NSString *typeWithoutStar = [[type substringToIndex:type.length-1]stringByReplacingOccurrencesOfString:@" " withString:@""];
                otherContent = [NSString stringWithFormat:@"\n\t\t_<name> = [%@ new];",typeWithoutStar];
                
                type = [[type substringToIndex:type.length-1] stringByAppendingString:@" *"];
            }
            replaceGetter = [NSString stringWithFormat:defaultReplaceGetterOfPointer,otherContent];
        }
        replaceContent = [[NSString stringWithFormat:@"- (%@)<name>\n%@",type,replaceGetter] stringByReplacingOccurrencesOfString:@"<name>" withString:name];
    }
    
    //如果是空白行就返回
    if ([replaceContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length<=0) {
        return;
    }
    
    //时间标签会替换成当前时间
//    if ([replaceContent rangeOfString:@"<datetime>"].location!=NSNotFound) {
//        replaceContent = [replaceContent stringByReplacingOccurrencesOfString:@"<datetime>" withString:[NSDate ml_nowString]];
//    }
    
    //完成替换
    [self.buffer.lines removeObjectAtIndex:lineNum];
    [self.buffer.lines insertObject:replaceContent atIndex:lineNum];
    
    //添加新的选中区域 注意如果不添加 Xcode 会在丢失选中后崩溃 可能是Xcode的bug
    XCSourceTextRange *selection = [[XCSourceTextRange alloc] initWithStart:XCSourceTextPositionMake(0, 0) end:XCSourceTextPositionMake(0, 0)];
    [self.buffer.selections removeAllObjects];
    [self.buffer.selections insertObject:selection atIndex:0];
    
}

@end
