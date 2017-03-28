//
//  ICGVideoTrimmerView.h
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Modified by Gavin Owens
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol ICGVideoTrimmerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ICGVideoTrimmerView : UIView

// Video to be trimmed
@property (strong, nonatomic, nullable) AVAsset *asset;

// Theme color for the trimmer view
@property (strong, nonatomic) UIColor *themeColor;

// Customize color for tracker
@property (assign, nonatomic) UIColor *trackerColor;

// Customize color for tracker head (the inverted triangle at top)
@property (assign ,nonatomic) UIColor *trackerHeadColor;

// Custom width for the top and bottom borders
@property (assign, nonatomic) CGFloat borderWidth;

@property (weak, nonatomic, nullable) id<ICGVideoTrimmerDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithAsset:(AVAsset *)asset;

- (instancetype)initWithFrame:(CGRect)frame asset:(AVAsset *)asset NS_DESIGNATED_INITIALIZER;

- (void)resetSubviews;

- (void)seekToTime:(CGFloat)startTime;

- (void)hideTracker:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END

@protocol ICGVideoTrimmerDelegate <NSObject>
- (void)trimmerView:(nonnull ICGVideoTrimmerView *)trimmerView currentPosition:(CGFloat)currentTime;
@end
