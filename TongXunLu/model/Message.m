//
//  Message.m
//  15-QQ聊天布局
//
//  Created by Liu Feng on 13-12-3.
//  Copyright (c) 2013年 Liu Feng. All rights reserved.
//

#import "Message.h"

@implementation Message

- (void)setDict:(NSDictionary *)dict{
    
    _dict = dict;
    
    self.icon = dict[@"icon"];
    self.time = dict[@"time"];
    self.content = dict[@"content"];
    self.state = NO;
    self.type = [dict[@"type"] intValue];
}

-(BOOL)isValidate
{
    BOOL isvalidate = YES;
    if ([self.icon isKindOfClass:[NSNull class]]) {
        isvalidate = NO;
    }
    if ([self.time isKindOfClass:[NSNull class]]) {
        isvalidate = NO;
    }
    if ([self.content isKindOfClass:[NSNull class]]) {
        isvalidate = NO;
    }

    return isvalidate;
}

-(NSString *)fullPathString:(NSString *)absolutePath
{
    return [NSString stringWithFormat:@"%@%@",BASEURL,absolutePath];
}

//-(MessageContentType)messageContentType
//{
//    MessageContentType type;
//    NSRange range = [self.content rangeOfString:@".amr|"];
//    if(range.length == 0)
//    {
//        NSRange range1 = [self.content rangeOfString:@"|IMAGE"];
//        if ((range1.location > 0) && (range1.length > 0)) {
//            type = MessageContentImage;
//        }else{
//            type = MessageContentText;
//        }
//    }
//    else if ((range.location > 0) && (range.length > 0) ) {
//        type =  MessageContentVoice;
//    }
//    return type;
//}

-(NSString *)fulltThumbnailsPath
{
    NSString *thumbnailsPath = nil;
    if (_contentType == MessageContentImage) {
        NSRange range = [self.content rangeOfString:@"|IMAGE"];
        if ((range.length > 0) && (range.location > 0)) {
            NSString *path = [self.content substringToIndex:range.location];
            NSString *serverImagePath = [NSString stringWithFormat:@"%@/UpLoadFile/%@",BASEURL,path];
            NSRange range1 = [serverImagePath rangeOfString:@".jpeg"];
            if ((range1.length > 0) && (range1.location > 0)) {
                thumbnailsPath = [serverImagePath stringByReplacingCharactersInRange:range1 withString:@"_s.jpeg"];
            }
        }
    }
    return thumbnailsPath;
}

-(NSString *)fullServerImagePath
{
    NSString *imagePath = nil;
    if (_contentType == MessageContentImage) {
        NSRange range = [self.content rangeOfString:@"|IMAGE"];
        if ((range.length > 0) && (range.location > 0)) {
            NSString *path = [self.content substringToIndex:range.location];
            imagePath = [NSString stringWithFormat:@"%@/UpLoadFile/%@",BASEURL,path];
        }
    }
    return imagePath;
}
@end
