//
//  MarkUpParser.h
//  gtg1.0
//
//  Created by zhoubin@moshi on 14-4-15.
//  Copyright (c) 2014年 lijx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface MarkUpParser : NSObject
{
    NSString       *font;
    UIColor        *color;
    UIColor        *strokeColor;
    float          strokeWidth;
    
    NSMutableArray *images;
}

@property (retain,nonatomic) NSString       *font;
@property (retain,nonatomic) UIColor        *color;
@property (retain,nonatomic) UIColor        *strokeColor;
@property (assign,readwrite) float          strokeWidth;

@property (retain,nonatomic) NSMutableArray *images;

-(NSMutableAttributedString *)attrStringFromMarkUp:(NSString *)html;

@end
