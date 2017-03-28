//
//  RNVisualSeekBarView.m
//  RNVisualSeekBar
//
//  Created by Shahen Hovhannisyan on 11/14/16.
//  Modified by Gavin Owens on 3/25/17.
//

#import "RCTConvert.h"
#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"

#import "RNVisualSeekBarView.h"
#import "ICGVideoTrimmerView.h"

@import UIKit;
@import AVKit;

@implementation RNVisualSeekBarView
{
  ICGVideoTrimmerView *_trimmerView;
  RCTEventDispatcher *_eventDispatcher;
  AVAsset *_asset;
  CGRect _rect;
  UIColor *_themeColor;
  CGFloat _thumbWidth;
  UIColor *_trackerColor;
  UIColor *_trackerHeadColor;
  UIColor *_timeColor;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  if ((self = [super initWithFrame:CGRectZero])) {
    _eventDispatcher = eventDispatcher;
    _trackerColor = [UIColor clearColor];
    _trackerHeadColor = [UIColor clearColor];
    _themeColor = [UIColor clearColor];
    _rect = CGRectZero;
  }

  return self;
}

#pragma mark - Properties

- (void)setSource:(NSDictionary *)source
{
    NSString *uri = [source objectForKey:@"uri"];
    if (uri != nil) {
      NSURL *pathToSource = [NSURL URLWithString:uri];
      _asset = [AVURLAsset assetWithURL:pathToSource];

      _trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:_rect asset:_asset];
      [_trimmerView hideTracker:false];
      _trimmerView.delegate = self;
      _trimmerView.trackerColor = _trackerColor;
      [self addSubview:_trimmerView];
      [self updateView];
    }
}

- (void)setHeight:(NSNumber *)height
{
  _rect.size.height = [RCTConvert CGFloat:height];
  [self updateView];
}

- (void)setWidth:(NSNumber *)width
{
  _rect.size.width = [RCTConvert CGFloat:width];
  [self updateView];
}

- (void)setThemeColor:(NSString *)themeColor
{
  NSNumber *newColor = [[[NSNumberFormatter alloc] init] numberFromString:themeColor];
  _themeColor = [RCTConvert UIColor:newColor];
  [self updateView];
}

- (void)setCurrentTime:(NSNumber *)currentTime
{
  if (_trimmerView != nil) {
    [_trimmerView seekToTime:[currentTime floatValue]];
  }
}

- (void)setThumbWidth:(NSNumber *)thumbWidth
{
  _thumbWidth = [RCTConvert CGFloat:thumbWidth];
  [self updateView];
}

- (void)setTrackerColor:(NSString *)trackerColor
{
  if (_trimmerView != nil) {
    NSNumber *newColor = [[[NSNumberFormatter alloc] init] numberFromString:trackerColor];
    _trackerColor = [RCTConvert UIColor:newColor];
    [self updateView];
  }
}

- (void)setTrackerHeadColor:(NSString *)trackerHeadColor
{
  if (_trimmerView != nil) {
    NSNumber *newColor = [[[NSNumberFormatter alloc] init] numberFromString:trackerHeadColor];
    _trackerHeadColor = [RCTConvert UIColor:newColor];
    [self updateView];
  }
}

- (void)setTimeColor:(NSString *)timeColor
{
  if (_trimmerView != nil) {
    NSNumber *newColor = [[[NSNumberFormatter alloc] init] numberFromString:timeColor];
    _timeColor = [RCTConvert UIColor:newColor];
    [self updateView];
  }
}


#pragma mark - Trimmer Delegate Methods

- (void)trimmerView:(nonnull ICGVideoTrimmerView *)trimmerView currentPosition:(CGFloat)currentTime {
  if (self.onTrackerMove != nil) {
    self.onTrackerMove(@{
                         @"currentTime": [NSNumber numberWithFloat:currentTime]
                         });
  }
}


#pragma mark - View methods

- (void)updateView
{
  self.frame = _rect;
  if (_trimmerView != nil) {
    _trimmerView.frame = _rect;
    _trimmerView.themeColor = _themeColor;
    _trimmerView.trackerColor = _trackerColor;
    _trimmerView.trackerHeadColor = _trackerHeadColor;
    _trimmerView.timeColor = _timeColor;
    [_trimmerView resetSubviews];
  }
}

@end
