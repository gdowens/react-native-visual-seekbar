//
//  RNVisualSeekBarView.h
//  RNVisualSeekBar
//
//  Created by Shahen Hovhannisyan on 11/14/16.
//  Modified by Gavin Owens on 3/25/17.
//

#import "RCTView.h"
#import "ICGVideoTrimmerView.h"

@class RCTEventDispatcher;

@interface RNVisualSeekBarView : RCTView <ICGVideoTrimmerDelegate>
- (instancetype) initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) RCTBubblingEventBlock onTrackerMove;

@end
