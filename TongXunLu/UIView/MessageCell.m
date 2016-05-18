//
//  MessageCell.m
//  15-QQ聊天布局
//
//  Created by Liu Feng on 13-12-3.
//  Copyright (c) 2013年 Liu Feng. All rights reserved.
//

#import "MessageCell.h"
#import "Message.h"
#import "MessageFrame.h"
#import "UIImageView+WebCache.h"

#import "SMessageDB.h"
#import "MJPhoto.h"
#import "MJPhotoBrowser.h"

@interface MessageCell ()
{
    UIButton     *_timeBtn;
    UIImageView *_iconView;
    UIButton    *_contentBtn;
    UIButton   *_iconViewBtn;
}

@end

@implementation MessageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
//#warning 必须先设置为clearColor，否则tableView的背景会被遮住
        self.backgroundColor = [UIColor clearColor];
        
        // 1、创建时间按钮
        _timeBtn = [[UIButton alloc] init];
        [_timeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _timeBtn.titleLabel.font = kTimeFont;
        _timeBtn.enabled = NO;
        [_timeBtn setBackgroundImage:[UIImage imageNamed:@"chat_timeline_bg.png"] forState:UIControlStateNormal];
        [self.contentView addSubview:_timeBtn];
        
        // 2、创建头像
        _iconView = [[UIImageView alloc] init];
        [self.contentView addSubview:_iconView];
        
        _iconViewBtn = [[UIButton alloc] init];
        [self.contentView addSubview:_iconViewBtn];
        
        // 3、创建内容
        _contentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_contentBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        _contentBtn.titleLabel.font = kContentFont;
        _contentBtn.titleLabel.numberOfLines = 0;
        [self.contentView addSubview:_contentBtn];
        
        //4、 创建菊花
        _juhua = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:_juhua];
        
        //5、 消息发送失败图片
        _messageSendFailedImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MessageListSendFail"]];
        [self.contentView addSubview:_messageSendFailedImageView];
    }
    return self;
}

-(void)setIndex:(NSInteger)value{
    _index = value;
    _contentBtn.tag = _index;
    _iconViewBtn.tag = _index;
}


-(void)setDelegate:(id)value{
    _delegate = value;
    
    if(_delegate && _didTouch)
        [_contentBtn addTarget:_delegate action:_didTouch forControlEvents:UIControlEventTouchUpInside];
}

-(void)setDidTouch:(SEL)value{
    _didTouch = value;
    
    if(_delegate && _didTouch)
        [_contentBtn addTarget:_delegate action:_didTouch forControlEvents:UIControlEventTouchUpInside];
}

-(void)setDidTouchIcon:(SEL)didTouchIcon
{
    _didTouchIcon = didTouchIcon;
    if (_delegate && _didTouchIcon) {
        [_iconViewBtn addTarget:_delegate action:_didTouchIcon forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)showImage
{
    NSString *fullImagePath = [_messageFrame.message fullServerImagePath];
    SMessageDB *msgdb = [[SMessageDB alloc] init];
    NSMutableArray *messageList = [msgdb selectImageMessageWithUid:_messageFrame.message.memberId WithContactUid:_messageFrame.hostMemberId];
    NSMutableArray *imageUrlList = [self imageUrlListWithAllMessage:messageList];
    if (imageUrlList.count > 0) {
        NSMutableArray *photos = [NSMutableArray arrayWithCapacity:imageUrlList.count];
        for(NSString *url in imageUrlList) {
            // 替换为中等尺寸图片
            MJPhoto *photo = [[MJPhoto alloc] init];
            photo.url = [NSURL URLWithString:url]; // 图片路径
            photo.srcImageView = _contentBtn.imageView; // 来源于哪个UIImageView
            [photos addObject:photo];
        }
        
        // 2.显示相册
        MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
        browser.currentPhotoIndex = [self indexOfMessageUrl:fullImagePath inImageUrlList:imageUrlList]; // 弹出相册时显示的第一张图片是？
        browser.photos = photos; // 设置所有的图片
        [browser show];
    }
}

-(NSMutableArray *)imageUrlListWithAllMessage:(NSMutableArray *)messageList
{
    NSMutableArray *imageList = [[NSMutableArray alloc] init];
    if (messageList != nil) {
        for (Message *message in messageList) {
            MessageContentType contentType = message.contentType;
            if (contentType == MessageContentImage) {
                NSString *fullPath = [message fullServerImagePath];
                [imageList addObject:fullPath];
            }
        }
    }
    
    return imageList;
}

-(NSUInteger)indexOfMessageUrl:(NSString *)messageUrl inImageUrlList:(NSMutableArray *)imageUrlList
{
    NSUInteger i = 0;
    if ((imageUrlList != nil) && (messageUrl != nil)) {
        for (i = 0; i<imageUrlList.count; i++) {
            NSString *url = [imageUrlList objectAtIndex:i];
            if ([messageUrl isEqualToString:url]) {
                break;
            }
        }
    }
    if (i == imageUrlList.count) {
        i=0;
    }
    return i;
}

- (void)setMessageFrame:(MessageFrame *)messageFrame{
    _delegate = nil;
    _didTouch = nil;
    _didTouchIcon = nil;
    
    _messageFrame = messageFrame;
    Message *message = _messageFrame.message;
    
    // 1、设置时间
    [_timeBtn setTitle:message.time forState:UIControlStateNormal];

    _timeBtn.frame = _messageFrame.timeF;
    
    // 2、设置头像
    [_iconView setImageWithURL:[NSURL URLWithString:message.icon] placeholderImage:[UIImage imageNamed:@"Download_Fail@2x.png"]];
    _iconView.frame = _messageFrame.iconF;
    
    _iconViewBtn.frame = _messageFrame.iconF;
    
    // 3、设置内容
    UIImage *normal , *focused;
    if (message.type == MessageTypeMe) {
        
        normal = [UIImage imageNamed:@"chatto_bg_normal.png"];
        normal = [normal stretchableImageWithLeftCapWidth:normal.size.width * 0.5 topCapHeight:normal.size.height * 0.7];
        focused = [UIImage imageNamed:@"chatto_bg_focused.png"];
        focused = [focused stretchableImageWithLeftCapWidth:focused.size.width * 0.5 topCapHeight:focused.size.height * 0.7];
    }else{
        
        normal = [UIImage imageNamed:@"chatfrom_bg_normal.png"];
        normal = [normal stretchableImageWithLeftCapWidth:normal.size.width * 0.5 topCapHeight:normal.size.height * 0.7];
        focused = [UIImage imageNamed:@"chatfrom_bg_focused.png"];
        focused = [focused stretchableImageWithLeftCapWidth:focused.size.width * 0.5 topCapHeight:focused.size.height * 0.7];
        
    }
    [_contentBtn setBackgroundImage:normal forState:UIControlStateNormal];
    [_contentBtn setBackgroundImage:focused forState:UIControlStateHighlighted];
    _contentBtn.frame = _messageFrame.contentF;
    
    if (message.code == MessageCodeText) {
        CGRect juhuaFrame;
        CGRect messageFailedImageFrame;
        MessageContentType type = message.contentType;
        if (type == MessageContentText) {
            //[_contentBtn setTitle:message.content forState:UIControlStateNormal];
            CGRect frame;
            if (message.type == MessageTypeMe) {
                frame = CGRectMake(14,10,CGRectGetWidth(_messageFrame.messageLabel.frame),CGRectGetHeight(_messageFrame.messageLabel.frame));
                juhuaFrame = CGRectMake(_messageFrame.contentF.origin.x-20,_messageFrame.contentF.origin.y+_messageFrame.contentF.size.height/2-9,18,18);
                messageFailedImageFrame = CGRectMake(_messageFrame.contentF.origin.x-20,_messageFrame.contentF.origin.y+_messageFrame.contentF.size.height/2-9,18,18);
            }else{
                frame = CGRectMake(24,10,CGRectGetWidth(_messageFrame.messageLabel.frame),CGRectGetHeight(_messageFrame.messageLabel.frame));
                juhuaFrame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width,_messageFrame.contentF.origin.y+_messageFrame.contentF.size.height/2-9,18,18);
                messageFailedImageFrame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width,_messageFrame.contentF.origin.y+_messageFrame.contentF.size.height/2-9,18,18);
            }
            _messageFrame.messageLabel.frame = frame;
            [CustomMethod drawImage:_messageFrame.messageLabel];
            [_contentBtn addSubview:_messageFrame.messageLabel];
            
        }else if (type == MessageContentVoice){
            int timelength = 0;
            NSArray *array = [message.content componentsSeparatedByString:@".amr|"];
            if ((array != nil) || (array.count >= 2)) {
                timelength = [[array lastObject] intValue];
            }

            UIImageView* iv = [[UIImageView alloc] init];
            iv.image =  [UIImage imageNamed:@"VoiceNodePlaying@2x.png"];
            
            UILabel* p = [[UILabel alloc] init];
            p.text = [NSString stringWithFormat:@"%d''",timelength];
            p.backgroundColor = [UIColor clearColor];
            p.textColor = [UIColor grayColor];
            p.font = [UIFont systemFontOfSize:11];
            
            if(message.type == MessageTypeMe){
                iv.frame = CGRectMake(_messageFrame.contentF.size.width-45, 10, 19, 19);
                p.frame = CGRectMake(_messageFrame.contentF.origin.x-50, _messageFrame.contentF.origin.y+10, 50, 15);
                [p setTextAlignment:NSTextAlignmentRight];
                
                juhuaFrame = CGRectMake(_messageFrame.contentF.origin.x+10, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);
                messageFailedImageFrame = CGRectMake(_messageFrame.contentF.origin.x-35, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);

            }
            else{
                iv.frame = CGRectMake(25, 10, 19, 19);
                p.frame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width+3, _messageFrame.contentF.origin.y+10, 50, 15);
                p.textAlignment = NSTextAlignmentLeft;
                
                juhuaFrame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width-30, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);
                messageFailedImageFrame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width+20, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);
            }
            [self.contentView addSubview:p];
            [_contentBtn addSubview:iv];

        }else if (type == MessageContentImage){
            NSString *thumbnailsPath = [message fulltThumbnailsPath];
            if (thumbnailsPath != nil) {
                UIButton *imageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                [imageBtn addTarget:self action:@selector(showImage) forControlEvents:UIControlEventTouchUpInside];
                if (message.type == MessageTypeMe) {
                    imageBtn.frame = CGRectMake(9, 2, _messageFrame.contentF.size.width-28, _messageFrame.contentF.size.height-14);
                    juhuaFrame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width/2-15, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);
                    messageFailedImageFrame = CGRectMake(_messageFrame.contentF.origin.x-20, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);
                }else{
                    imageBtn.frame = CGRectMake(19, 2, _messageFrame.contentF.size.width-28, _messageFrame.contentF.size.height-14);
                    juhuaFrame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width/2, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);
                    messageFailedImageFrame = CGRectMake(_messageFrame.contentF.origin.x+_messageFrame.contentF.size.width, _messageFrame.contentF.origin.y + _messageFrame.contentF.size.height/2-9, 18, 18);
                }
                [imageBtn.layer setMasksToBounds:YES];
                [imageBtn.layer setCornerRadius:10.0]; //设置矩形四个圆角半径
                [imageBtn.layer setBorderWidth:1.0]; //边框宽度
                
                UIImageView *imageBtnView = [[UIImageView alloc] init];
                [imageBtnView setImageWithURL:[NSURL URLWithString:thumbnailsPath] placeholderImage:[UIImage imageNamed:@"Download_Fail@2x.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                    NSLog(@"%@",error);
                    if (!error) {
                        [imageBtn setBackgroundImage:image forState:UIControlStateNormal];
                    }
                }];
                
                [imageBtn addSubview:imageBtnView];
                [_contentBtn addSubview:imageBtn];
            }
        }
        
        if (message.type == MessageTypeMe) {
            _contentBtn.contentEdgeInsets = UIEdgeInsetsMake(kContentTop, kContentRight, kContentBottom, kContentLeft);
        }else{
            _contentBtn.contentEdgeInsets = UIEdgeInsetsMake(kContentTop, kContentLeft, kContentBottom, kContentRight);
        }
        
        _juhua.frame = juhuaFrame;
        _messageSendFailedImageView.frame = messageFailedImageFrame;
        
        [self markStateSettingWithMessage:message];
    }
}

-(void)markStateSettingWithMessage:(Message *)message
{
    if (message.state == MessageIsSend) {
        [_messageSendFailedImageView setHidden:YES];
        [_juhua setHidden:NO];
        [_juhua startAnimating];
    }else if(message.state == MessageFailed){
        [_messageSendFailedImageView setHidden:NO];
        if ([_juhua isAnimating]) {
            [_juhua stopAnimating];
        }
    }else if(message.state == MessageSuccess)
    {
        [_messageSendFailedImageView setHidden:YES];
        if ([_juhua isAnimating]) {
            [_juhua stopAnimating];
        }
    }
}

@end
