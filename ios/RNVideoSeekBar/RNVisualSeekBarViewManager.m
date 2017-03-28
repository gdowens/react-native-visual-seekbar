//
//  RNVisualSeekBarViewManager.m
//  RNVisualSeekBar
//
//  Created by Shahen Hovhannisyan on 11/14/16.
//  Modified by Gavin Owens on 3/25/17.
//

#import "RNVisualSeekBarViewManager.h"
#import "RNVisualSeekBarView.h"
#import "RCTBridge.h"

@implementation RNVisualSeekBarViewManager

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (UIView *)view
{
  return [[RNVisualSeekBarView alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}


- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(width, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(height, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(onTrackerMove, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(currentTime, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(themeColor, NSString);
RCT_EXPORT_VIEW_PROPERTY(trackerColor, NSString);
RCT_EXPORT_VIEW_PROPERTY(trackerHeadColor, NSString);
RCT_EXPORT_VIEW_PROPERTY(timeColor, NSString);


@end
