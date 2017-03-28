//
//  ICGVideoTrimmerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Modified by Gavin Owens
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "ICGVideoTrimmerView.h"

@interface ICGVideoTrimmerView() <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *frameView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (strong, nonatomic) UIView *trackerView;
@property (strong, nonatomic) UIView *topBorder;
@property (strong, nonatomic) UIView *bottomBorder;
@property (strong, nonatomic) UILabel *timeText;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic) BOOL panning;
@property (nonatomic) BOOL viewsInitialized;
@property (nonatomic) CGFloat offset;
@property (nonatomic) CGFloat time;
@property (nonatomic) CGFloat widthPerSecond;

@end

@implementation ICGVideoTrimmerView

#pragma mark - Initiation

- (instancetype)initWithFrame:(CGRect)frame
{
  NSAssert(NO, nil);
  @throw nil;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
  return [super initWithCoder:aDecoder];
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
  return [self initWithFrame:CGRectZero asset:asset];
}

- (instancetype)initWithFrame:(CGRect)frame asset:(AVAsset *)asset
{
  self = [super initWithFrame:frame];
  if (self) {
    _asset = asset;
    _viewsInitialized = NO;
    [self resetSubviews];
  }
  return self;
}


#pragma mark - Private methods

- (UIColor *)themeColor
{
  return _themeColor ?: [UIColor lightGrayColor];
}

- (CGFloat)maxLength
{
  return 15;
}

- (CGFloat)minLength
{
  return 3;
}

- (UIColor *)trackerColor
{
  return _trackerColor ?: [UIColor whiteColor];
}

- (UIColor *)trackerHeadColor
{
  return _trackerHeadColor ?: [UIColor whiteColor];
}

- (CGFloat)borderWidth
{
  return _borderWidth ?: 1;
}

- (UIView *) createTrackerView
{
  CGFloat containerWidth = 30;
  CGFloat base = 10.0;
  CGFloat height = base;
  UIView *trackerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerWidth, CGRectGetHeight(self.contentView.frame) + 20)];
  trackerContainer.clipsToBounds = NO;
  trackerContainer.layer.masksToBounds = NO;
//  trackerContainer.layer.masksToBounds = false;

  // create triangle mask
  UIBezierPath* trianglePath = [UIBezierPath bezierPath];
  [trianglePath moveToPoint:CGPointMake(base/2, height)];
  [trianglePath addLineToPoint:CGPointMake(0,0)];
  [trianglePath addLineToPoint:CGPointMake(base, 0)];
  [trianglePath closePath];
  CAShapeLayer *triangleMaskLayer = [CAShapeLayer layer];
  triangleMaskLayer.cornerRadius = base/2;
  [triangleMaskLayer setPath:trianglePath.CGPath];


  // create triangle view
  UIView *triangle = [[UIView alloc] initWithFrame:CGRectMake(containerWidth/2 - base/2, 0, base, height)];
  triangle.backgroundColor = self.trackerHeadColor;
  triangle.layer.mask = triangleMaskLayer;
  [trackerContainer addSubview:triangle];

  // create line view
  UIView *tracker = [[UIView alloc] initWithFrame:CGRectMake(containerWidth/2 - 0.5, 0, 1, CGRectGetHeight(self.contentView.frame) + 20)];
  tracker.backgroundColor = self.trackerColor;
  tracker.layer.cornerRadius = 2;
  [trackerContainer addSubview:tracker];

  //addText
  CGFloat textYOffset = CGRectGetHeight(self.frameView.frame);
  self.timeText = [[UILabel alloc] initWithFrame:CGRectMake(containerWidth/2 + 5, 0, containerWidth/2, 15)];
  [self updateTimeText];
  [self.timeText sizeToFit];
  self.timeText.font = [UIFont systemFontOfSize:12];
  self.timeText.numberOfLines = 1;
  self.timeText.clipsToBounds = NO;
  self.timeText.textAlignment = NSTextAlignmentLeft;
  self.timeText.backgroundColor = [UIColor clearColor];
  self.timeText.textColor = [UIColor whiteColor];

  [trackerContainer addSubview:self.timeText];

  return trackerContainer;
}

- (void) updateTimeText
{
  int m = fmod(trunc((self.time / 60.0)), 60.0);
  int s = fmod(self.time, 60.0);

  NSString *formattedTime = [NSString stringWithFormat:@"%02u:%02u", m, s];
  self.timeText.text = formattedTime;
}

- (void)resetSubviews
{
  self.clipsToBounds = YES;

  [self setBackgroundColor:[UIColor clearColor]];

  [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

  self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
  [self.scrollView setBounces:NO];
  [self.scrollView setScrollEnabled:NO];
  [self addSubview:self.scrollView];
  [self.scrollView setDelegate:self];
  [self.scrollView setShowsHorizontalScrollIndicator:NO];

  self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
  [self.scrollView setContentSize:self.contentView.frame.size];
  [self.scrollView addSubview:self.contentView];

  CGFloat ratio = 0.7;
  _offset = CGRectGetHeight(self.contentView.frame) - CGRectGetHeight(self.contentView.frame)*ratio;
  self.frameView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame)*ratio)];

  [self.frameView.layer setMasksToBounds:YES];
  [self.contentView addSubview:self.frameView];
  self.frameView.frame = CGRectOffset(self.frameView.frame, 0.0f, _offset);
  UITapGestureRecognizer *touchTracker = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveTrackerLayer:)];
  touchTracker.delegate = self;
  [self.frameView addGestureRecognizer:touchTracker];

  [self addFrames];

  // add borders
  self.topBorder = [[UIView alloc] init];
  [self.topBorder setBackgroundColor:self.themeColor];
  [self addSubview:self.topBorder];

  self.bottomBorder = [[UIView alloc] init];
  [self.bottomBorder setBackgroundColor:self.themeColor];
  [self addSubview:self.bottomBorder];

  self.trackerView = [self createTrackerView];
  CGRect trackerFrame = self.trackerView.frame;
  trackerFrame.origin.x = self.time;
  self.trackerView.frame = trackerFrame;

  [self.trackerView setUserInteractionEnabled:YES];
  [self.contentView addSubview:self.trackerView];

  self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTrackerPan:)];

  [self.panGestureRecognizer locationInView:self.trackerView];

  [self.trackerView addGestureRecognizer:self.panGestureRecognizer];
}

- (void)handleTrackerPan: (UIPanGestureRecognizer *) recognizer {
  CGPoint point = [self.panGestureRecognizer locationInView:self.trackerView];

  if (recognizer.state == UIGestureRecognizerStateEnded) {
    self.panning = NO;
  } else {
    self.panning = YES;
  }

  CGRect trackerFrame = self.trackerView.frame;
  trackerFrame.origin.x += point.x;
  self.trackerView.frame = trackerFrame;
  CGFloat time = trackerFrame.origin.x / self.widthPerSecond;
  self.time = time;
  [self updateTimeText];
  [self scrollViewMightAdjust:NO];
  [self.delegate trimmerView:self currentPosition:time ];

}

- (void)moveTrackerLayer:(UITapGestureRecognizer *)gesture
{
  CGPoint point = [gesture locationInView:self.frameView];
  CGRect trackerFrame = self.trackerView.frame;
  trackerFrame.origin.x = point.x;
  self.trackerView.frame = trackerFrame;
  CGFloat time = trackerFrame.origin.x / self.widthPerSecond;
  self.time = time;
  [self updateTimeText];
  [self scrollViewMightAdjust:YES toCenter:YES];
  [self.delegate trimmerView:self currentPosition:self.time];
}

- (void)scrollViewMightAdjust:(BOOL)animated toCenter:(BOOL)toCenter
{
  [self scrollViewMightAdjust:animated toCenter:toCenter withDelta:0.0f];
}

- (void)scrollViewMightAdjust: (BOOL) animated
{
  [self scrollViewMightAdjust:animated toCenter:NO withDelta:0.0f];
}

- (void)scrollViewMightAdjust: (BOOL) animated toCenter:(BOOL)toCenter withDelta:(CGFloat)withDelta
{
  // the frames in frameView are still being setup
  if (!_viewsInitialized) {
    return;
  }

  CGFloat newPoint;
  CGFloat MAX_RIGHT_OFFSET = self.contentView.layer.frame.size.width - self.layer.frame.size.width + 20;
  UIViewAnimationOptions options = UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction;

  // case where the tracker is hidden
  if (self.trackerView.frame.origin.x < self.scrollView.contentOffset.x) {
    newPoint = self.trackerView.frame.origin.x;
  // case where tracker is moving and we're adding a delta onto the offset
  } else if (withDelta != 0) {
    newPoint = self.scrollView.contentOffset.x + withDelta;
  // case where there is a tap and we want to center the tracker
  } else if (toCenter) {
    newPoint = self.trackerView.frame.origin.x - self.layer.frame.size.width/2;
  // user is panning and we want to move the offset by some ratio of its proximity to the edge
  } else {
    // nearing the edges
    CGFloat trackerRelativePosition = self.trackerView.frame.origin.x - (self.scrollView.contentOffset.x);
    CGFloat midpoint = self.layer.frame.size.width / 2;
    CGFloat distanceRatio = (trackerRelativePosition - midpoint)/midpoint;
    CGFloat amountToShift = (midpoint / 15) * distanceRatio;
    newPoint = self.scrollView.contentOffset.x + amountToShift;

    // allow some panning in the middle without movement
    if ((distanceRatio < 0 && (-1.0 *distanceRatio) < 0.55)) {
      return;
    }
    if (distanceRatio > 0 && distanceRatio < 0.55) {
      return;
    }
  }

  // edge cases where scrollView is at the start or end of its content
  if (newPoint <= 0) {
    newPoint = 0.0;
  }
  if (newPoint > MAX_RIGHT_OFFSET) {
    newPoint = MAX_RIGHT_OFFSET;
  }

  // panning gesture needs to loop on itself for continues scroll
  // and cancel previous animations to prevent runaway callback hell
  if (self.panning) {
    [CATransaction begin];
    [self.scrollView.layer removeAllAnimations];
    [CATransaction commit];
    [UIView animateWithDuration:0.5f delay:0 options:options animations:^{
      self.scrollView.contentOffset = CGPointMake(newPoint, self.scrollView.contentOffset.y);
    } completion:^(BOOL finished){
      if (self.panning) {
        [self scrollViewMightAdjust:NO];
      }
    }];
  } else {
    [UIView animateWithDuration:0.5f delay:0 options:options animations:^{
      self.scrollView.contentOffset = CGPointMake(newPoint, self.scrollView.contentOffset.y);
    } completion:NULL];
  }
}

- (void)seekToTime:(CGFloat) time
{
  [self updateTimeText];
  BOOL animateTransition = trunc(time*100) != trunc(self.time*100);
  self.time = time;
  CGFloat posToMove = time * self.widthPerSecond;
  CGRect trackerFrame = self.trackerView.frame;
  CGFloat delta = posToMove - trackerFrame.origin.x;
  trackerFrame.origin.x = posToMove;

  if (animateTransition) {
    UIViewAnimationOptions options = UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction;
    [UIView animateWithDuration:.7
                          delay:0
                        options:options
                     animations:^{
                       //what you would like to animate
                       self.trackerView.frame = trackerFrame;
                     }completion:^(BOOL finished){
                       //do something when the animation finishes
                     }];
    [self scrollViewMightAdjust:YES toCenter:NO withDelta:delta];
  }
}

- (void)hideTracker:(BOOL)flag
{
  self.trackerView.hidden = flag;
}

- (void)addFrames
{
  self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
  self.imageGenerator.appliesPreferredTrackTransform = YES;
  if ([self isRetina]){
    self.imageGenerator.maximumSize = CGSizeMake(CGRectGetWidth(self.frameView.frame)*2, CGRectGetHeight(self.frameView.frame)*2);
  } else {
    self.imageGenerator.maximumSize = CGSizeMake(CGRectGetWidth(self.frameView.frame), CGRectGetHeight(self.frameView.frame));
  }

  CGFloat picWidth = 0;

  // First image
  NSError *error;
  CMTime actualTime;
  CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
  UIImage *videoScreen;
  if ([self isRetina]){
    videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
  } else {
    videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
  }
  if (halfWayImage != NULL) {
    UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
    CGRect rect = tmp.frame;
    rect.size.width = videoScreen.size.width;
    tmp.frame = rect;
    [self.frameView addSubview:tmp];
    picWidth = tmp.frame.size.width / 3;
    CGImageRelease(halfWayImage);
  }

  Float64 duration = CMTimeGetSeconds([self.asset duration]);
  CGFloat screenWidth = CGRectGetWidth(self.frame); // quick fix to make up for the width of thumb views
  NSInteger actualFramesNeeded;

  CGFloat frameViewFrameWidth = (duration / self.maxLength) * screenWidth;
  [self.frameView setFrame:CGRectMake(0, _offset, frameViewFrameWidth, CGRectGetHeight(self.frameView.frame))];
  CGFloat contentViewFrameWidth = CMTimeGetSeconds([self.asset duration]) <= self.maxLength + 0.5 ? screenWidth + 30 : frameViewFrameWidth;
  [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth, CGRectGetHeight(self.contentView.frame))];
  [self.scrollView setContentSize:self.contentView.frame.size];
  NSInteger minFramesNeeded = screenWidth / picWidth + 1;
  actualFramesNeeded =  (duration / self.maxLength) * minFramesNeeded + 1;

  Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
  self.widthPerSecond = frameViewFrameWidth / duration;

  int preferredWidth = 0;
  NSMutableArray *times = [[NSMutableArray alloc] init];
  for (int i=1; i<actualFramesNeeded; i++){

    CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame, 600);
    [times addObject:[NSValue valueWithCMTime:time]];

    UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
    tmp.tag = i;

    CGRect currentFrame = tmp.frame;
    currentFrame.origin.x = i*picWidth;

    currentFrame.size.width = picWidth;
    tmp.contentMode = UIViewContentModeScaleAspectFill;
    tmp.clipsToBounds = YES;
    preferredWidth += currentFrame.size.width;

    if( i == actualFramesNeeded-1){
      currentFrame.size.width-=6;
    }
    tmp.frame = currentFrame;


    [self.frameView addSubview:tmp];
  }
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    for (int i=1; i<=[times count]; i++) {
      CMTime time = [((NSValue *)[times objectAtIndex:i-1]) CMTimeValue];

      CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];

      UIImage *videoScreen;
      if ([self isRetina]){
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
      } else {
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
      }

      CGImageRelease(halfWayImage);
      dispatch_async(dispatch_get_main_queue(), ^{
        UIImageView *imageView = (UIImageView *)[self.frameView viewWithTag:i];
        [imageView setImage:videoScreen];
        if (i > minFramesNeeded) {
          _viewsInitialized = YES;
        }
      });
    }
  });
}

- (BOOL)isRetina
{
  return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
          ([UIScreen mainScreen].scale > 1.0));
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  // do nothing for now
}

@end
