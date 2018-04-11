//
//  MDPlayProgressView.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDPlayProgressView.h"
#import "MDGraphicEqualizerDisplayLayer.h"
#import "MDConstants.h"


@interface MDPlayProgressView ()
@property (assign, nonatomic) float progress;
@property (nonatomic) CALayer *volumeContainerLayer;
@property (nonatomic) CALayer *imageLayer;
@property (nonatomic) CAShapeLayer *imageMaskLayer;
@property (nonatomic) CAShapeLayer *progressLayer;
@property (nonatomic) CAShapeLayer *progressBackground;
@property (nonatomic) CAShapeLayer *volumeShapeLayer;
@property (nonatomic) CAShapeLayer *volumeWavesShapeLayer;
@property (nonatomic) CAShapeLayer *volumeGuideShapeLayer;
@property (nonatomic) CAShapeLayer *volumeProgressShapeLayer;
@property (nonatomic) CAShapeLayer *volumeKnobShapeLayer;
@property (nonatomic) CAShapeLayer *menuShapeLayer;
@property (nonatomic) CAShapeLayer *graphicEQMenuShapeLayer;
@property (nonatomic) MDGraphicEqualizerDisplayLayer *EQAnalyzerDisplayLayer;
@property (nonatomic) UIImage *albumImage;
@property (assign, nonatomic) NSInteger animationSequence;
@property (assign, nonatomic) float volumeLevel;
@property (nonatomic) CGPoint gestureCalcPoint;
@property (assign, nonatomic) float borderWidth;
@property (assign, nonatomic) float pathWidth;
@property (assign, nonatomic) float innerSpace;
@property (assign, nonatomic) float menuPadding;
@property (nonatomic, assign) float menuScaleFactor;
@property (nonatomic) NSInteger menuTouchLocation;
@property (nonatomic) BOOL isEQVisible;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation MDPlayProgressView
@synthesize   playerViewDelegate;

#pragma mark - Lifecycle

float Degrees2Radians(float degrees) { return degrees * M_PI / 180; }

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _progress = 0.0f;
        _borderWidth = 10.0f;
        _innerSpace = 20.0f;
        _pathWidth = 4.0f;
        _volumeLevel = 0.4f;
        _menuPadding = 4.0f;
        _menuScaleFactor = 0.125f;
        _isEQVisible = false;
        [self setupLayers];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        _progress = 0.0f;
        _borderWidth = 10.0f;
        _innerSpace = 20.0f;
        _pathWidth = 4.0f;
        _volumeLevel = 0.4f;
        _menuPadding = 4.0f;
        _menuScaleFactor = 0.125f;
        _isEQVisible = false;
        [self setupLayers];
    }
    return self;
}


- (void)layoutSubviews{
    [super layoutSubviews];
    
    // setup bounds for image layer and mask
    float padding = [self calculatePadding];
    
    // we really want our rect to be a square - oval discs don't fit into a player too well!!
    float wh = [self calculateWidthAndHeightValue];

    CGRect bounds = CGRectMake(0.0f, 0.0f, wh , wh );
    
    //a little padding for the image
    CGRect imageBounds = CGRectMake(0.0f, 0.0f, wh -padding, wh - padding );
    [self.imageLayer setFrame:imageBounds];
    
    //calc offset for width/height adjustment
    float wOffset = (self.frame.size.width - wh) /2;
    float hOffset = (self.frame.size.height - wh) /2;
    float centerFrameWidth = self.frame.size.width / 2;
    float centerFrameHeight = self.frame.size.height /2;
    
    //set the placement to reflect offset and padding (center vertically or horizontally whichever is greater)
    self.imageLayer.position = CGPointMake(wOffset + padding /2, hOffset + padding / 2);
    self.imageLayer.position = CGPointMake(centerFrameWidth, centerFrameHeight);
    
    // create circular mask for image
    [self.imageMaskLayer setFrame:imageBounds];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithOvalInRect:self.imageMaskLayer.bounds];
    self.imageMaskLayer.path = maskPath.CGPath;
    self.imageLayer.mask = self.imageMaskLayer;
    
    // set a default image
    UIImage *defaultImage = [UIImage imageNamed:@"no_album_art.jpg"];
    if (self.albumImage) {
        defaultImage = self.albumImage;
    }
    [self.imageLayer setContents:(__bridge id)defaultImage.CGImage];
    
    // setup bounds for progress background
    CGRect progressBounds = CGRectMake(0.0f, 0.0f, wh - self.borderWidth, wh - self.borderWidth);
    [self.progressBackground setFrame:progressBounds];
    
    // Create progress layer and background
    UIBezierPath *progressBackgroundPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(bounds ), CGRectGetMidY(bounds))
                                                                          radius:(bounds.size.height - self.borderWidth - self.pathWidth ) / 2
                                                                          startAngle:(5* -M_PI / 12)
                                                                          endAngle: (2.0 * M_PI - 7 * M_PI /12)
                                                                          clockwise:YES];
   
    self.progressBackground.strokeColor =  [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.2f].CGColor;
    self.progressBackground.lineWidth = self.pathWidth; // +1.0f;
    self.progressBackground.path = progressBackgroundPath.CGPath;
    self.progressBackground.anchorPoint = CGPointMake(0.5f, 0.5f);
    self.progressBackground.position = CGPointMake(self.layer.frame.size.width / 2 -  self.borderWidth / 2, self.layer.frame.size.height / 2  - self.borderWidth / 2);
    self.progressBackground.fillColor = [UIColor clearColor].CGColor;
    
    
    // setup progress layer
    [self.progressLayer setFrame:progressBounds];
    UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
                                                                radius:(bounds.size.height - self.borderWidth - self.pathWidth   ) / 2
                                                                startAngle: (5* -M_PI / 12)
                                                                endAngle: (2.0 * M_PI - 7 * M_PI /12)
                                                                clockwise:YES];
   
    self.progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.progressLayer.lineWidth = self.pathWidth - 2.0f ;
    self.progressLayer.path = progressPath.CGPath;
    self.progressLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
    self.progressLayer.fillColor = [UIColor clearColor].CGColor;
    self.progressLayer.position = CGPointMake(self.layer.frame.size.width / 2 - self.borderWidth / 2, self.layer.frame.size.height / 2 - self.borderWidth/2);
    [self.progressLayer setStrokeEnd:0.0f];
   
    //graphicEQMenu layer
    self.graphicEQMenuShapeLayer.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(progressBounds) * self.menuScaleFactor, CGRectGetHeight(progressBounds) * self.menuScaleFactor);
    self.graphicEQMenuShapeLayer.strokeColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.5f].CGColor;
    self.graphicEQMenuShapeLayer.lineWidth = self.pathWidth * 0.8f;
    self.graphicEQMenuShapeLayer.path = [self makeGraphicEQIconConstrindToBounds:self.graphicEQMenuShapeLayer.frame];
    self.graphicEQMenuShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.graphicEQMenuShapeLayer.position = CGPointMake(self.borderWidth, 0.0f);
   
    
    //menu layer
    self.menuShapeLayer.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(progressBounds) * self.menuScaleFactor, CGRectGetHeight(progressBounds) * self.menuScaleFactor);
    self.menuShapeLayer.strokeColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.5f].CGColor;
    self.menuShapeLayer.lineWidth = self.pathWidth * 0.8f;
    self.menuShapeLayer.path = [self makeMenuLinesConstrainedToBounds:self.menuShapeLayer.frame];
    self.menuShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.menuShapeLayer.position = CGPointMake((self.progressLayer.frame.size.width - self.menuShapeLayer.frame.size.width /2), (CGRectGetHeight(progressBounds) * self.menuScaleFactor) - (self.pathWidth * 2));
   
    // calc for positioning of eq layers
    CGRect volumeGuideBounds = [self calculateVolumeGuideBoundsFromBounds:self.progressLayer.frame];
    CGRect eqFrame = CGRectMake(0.0f, 0.0f, wh - ((self.borderWidth + self.pathWidth   * 3)*3), wh - (volumeGuideBounds.size.height * 3)   );

    [self.EQAnalyzerDisplayLayer setFrame:eqFrame];
    self.EQAnalyzerDisplayLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
    self.EQAnalyzerDisplayLayer.position = CGPointMake(self.layer.frame.size.width / 2 , self.layer.frame.size.height / 2  );
    
    [self layoutVolumeContainer];
}

- (void)layoutVolumeContainer{
    //Create container for Volume
    self.volumeContainerLayer.masksToBounds = false;
    CGRect containerBounds = [self calculateVolumeGuideBoundsFromBounds:self.progressLayer.frame];
    [self.volumeContainerLayer setFrame:CGRectMake(0, 0, containerBounds.size.width , containerBounds.size.height )];
    
    //- Apply a transfor for touch area
    CATransform3D tfm = CATransform3DIdentity;
    tfm.m34 = -0.00001f;
    tfm = CATransform3DRotate(tfm, Degrees2Radians(-45.0), 0.0f, 0.0f, 1.0f);
    self.volumeContainerLayer.transform = tfm;
    self.volumeContainerLayer.position = CGPointMake(containerBounds.origin.x, containerBounds.origin.y);
    self.volumeContainerLayer.backgroundColor = [UIColor clearColor].CGColor;
    
    //Volume guide
    [self.volumeGuideShapeLayer setFrame:CGRectMake(0.0f, 0.0f,self.volumeContainerLayer.frame.size.width,self.volumeContainerLayer.frame.size.height)];
    self.volumeGuideShapeLayer.strokeColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.2f].CGColor;
    
    self.volumeGuideShapeLayer.path = [self createVolumeGuideFromBounds:self.frame];
    self.volumeGuideShapeLayer.strokeEnd = 1.0f;
    self.volumeGuideShapeLayer.lineWidth = 3.0f;
    self.volumeGuideShapeLayer.fillColor = [UIColor clearColor].CGColor;
    
    //Volume setting
    [self.volumeProgressShapeLayer setFrame:self.volumeGuideShapeLayer.frame];
    self.volumeProgressShapeLayer.strokeColor =  [UIColor whiteColor].CGColor;
    self.volumeProgressShapeLayer.path = [self createVolumeGuideFromBounds:self.frame];
    self.volumeProgressShapeLayer.fillColor = [UIColor clearColor].CGColor;
    [self setVolumeProgressSlider:self.volumeLevel];
    
    //volume Knob Setting
    [self.volumeKnobShapeLayer setFrame:CGRectMake(0.0f, 0.0f, 6.0f, 6.0f)];
    self.volumeKnobShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.volumeKnobShapeLayer.fillColor = [UIColor whiteColor].CGColor;
    
    //speaker
    [self.volumeShapeLayer setFrame:CGRectMake(0, 0, 16.0f, 12.0f)];
    self.volumeShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.volumeShapeLayer.fillColor = [UIColor whiteColor].CGColor;
    self.volumeShapeLayer.path = [self createVolumeShape];
    self.volumeShapeLayer.position = CGPointMake(self.volumeContainerLayer.bounds.size.width / 2, self.volumeContainerLayer.bounds.size.height / 2);
    
    // speaker needs to be rotated 45 degrees to counter rotation of parent layer
    CATransform3D tfm2 = CATransform3DIdentity;
    tfm2 = CATransform3DRotate(tfm2, Degrees2Radians(45.0), 0.0f, 0.0f, 1.0f);
    self.volumeShapeLayer.transform = tfm2;
    
    //speaker sound waves
    [self.volumeWavesShapeLayer setFrame:CGRectMake(0, 0, 8.0f, 12.0f)];
    self.volumeWavesShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.volumeWavesShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.volumeWavesShapeLayer.path = [self createVolumeWaveShape:3];
    self.volumeWavesShapeLayer.position = CGPointMake(8.0f, 0.0f);
    
    //UIBezierPath knobPath
    self.volumeKnobShapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.volumeKnobShapeLayer.frame].CGPath;
    self.volumeKnobShapeLayer.position =  [self calculateXYPointsForVolumeGuideEndFromBounds:self.progressBackground.frame distanceValue:1.0f];
    self.volumeContainerLayer.zPosition = 200;
}


#pragma mark - Setup view

- (void)setupLayers{
    
    self.backgroundColor = [UIColor clearColor];

    [self setClipsToBounds:NO];
    self.backgroundColor = [UIColor clearColor];
    
    self.imageMaskLayer = [CAShapeLayer layer];
    self.imageMaskLayer.anchorPoint = CGPointZero;
    
    self.imageLayer = [CALayer layer];
    
    
    self.progressLayer = [CAShapeLayer layer];
    self.progressLayer.anchorPoint = CGPointZero;
    self.progressLayer.lineCap = kCALineCapRound;
    
    self.progressBackground = [CAShapeLayer layer];
    self.progressBackground.anchorPoint = CGPointZero;
    self.progressBackground.lineCap = kCALineCapRound;
    
    self.volumeContainerLayer = [CALayer layer];
    self.volumeContainerLayer.anchorPoint =  CGPointZero;
    
    self.volumeGuideShapeLayer = [CAShapeLayer layer];
    self.volumeGuideShapeLayer.lineCap = kCALineCapRound;
    self.volumeGuideShapeLayer.anchorPoint = CGPointZero;
    
    self.volumeProgressShapeLayer = [CAShapeLayer layer];
    self.volumeProgressShapeLayer.lineCap = kCALineCapRound;
    self.volumeProgressShapeLayer.anchorPoint = CGPointZero;
    
    self.volumeShapeLayer = [CAShapeLayer layer];
    self.volumeShapeLayer.lineCap = kCALineCapRound;
    self.volumeShapeLayer.anchorPoint = CGPointZero;
    
    self.volumeWavesShapeLayer = [CAShapeLayer layer];
    self.volumeWavesShapeLayer.lineCap = kCALineCapRound;
    self.volumeWavesShapeLayer.anchorPoint = CGPointZero;
    
    self.volumeKnobShapeLayer = [CAShapeLayer layer];
    self.volumeKnobShapeLayer.anchorPoint = CGPointZero;
    
    self.graphicEQMenuShapeLayer = [CAShapeLayer layer];
    self.graphicEQMenuShapeLayer.anchorPoint = CGPointZero;
    
    self.menuShapeLayer = [CAShapeLayer layer];
    self.menuShapeLayer.anchorPoint =  CGPointMake(0.5f, 0.5f);
    
    self.EQAnalyzerDisplayLayer = [[MDGraphicEqualizerDisplayLayer alloc]initWithNumberOfBars:32];
    self.EQAnalyzerDisplayLayer.anchorPoint = CGPointZero;
    
    
    //build view higherarchie
    [self.volumeShapeLayer addSublayer:self.volumeWavesShapeLayer];
    [self.volumeContainerLayer addSublayer:self.volumeShapeLayer];
    [self.progressBackground addSublayer:self.volumeGuideShapeLayer];
    [self.progressBackground addSublayer:self.volumeProgressShapeLayer];
    [self.progressBackground addSublayer:self.menuShapeLayer];
    [self.progressBackground addSublayer:self.graphicEQMenuShapeLayer];
    [self.volumeProgressShapeLayer addSublayer:self.volumeKnobShapeLayer];
    [self.layer addSublayer:self.EQAnalyzerDisplayLayer];
    [self.layer addSublayer:self.progressBackground];
    [self.layer addSublayer:self.progressLayer];
    [self.layer addSublayer:self.imageLayer];
    
    [self.progressBackground addSublayer:self.volumeContainerLayer];
    
    [self scaleEQAnalayzerDisplay];
    
    CATransform3D tfmb = CATransform3DIdentity;
    CATransform3DScale(tfmb, 0.0f, 0.0f, 1.0f);
    
    CATransform3D tfmp = CATransform3DIdentity;
    CATransform3DScale(tfmp, 0.0f, 0.0f, 1.0f);
    
    [self.progressBackground addAnimation:[self makeScaleDownAnimationWithDuration:0.0f usingTransform:self.progressBackground.transform] forKey:@"scaledown"];
    [self.progressLayer addAnimation:[self makeScaleDownAnimationWithDuration:0.0f usingTransform:self.progressLayer.transform] forKey:@"scaledownp"];
    
    // setup gesture for Volume and Menu
    [self setupPanGesture];
    [self setupTapGesture];
    
}


- (CGPoint)calculateXYPointsForVolumeGuideEndFromBounds:(CGRect)bounds distanceValue:(CGFloat)endStrokeValue{
    float volumeShapeRadius = 4.5f + (bounds.size.height / 2);
    float volumeEndXpos = (volumeShapeRadius + volumeShapeRadius* cosf(M_PI/3 - M_PI/6 * endStrokeValue )) ;
    float volumeEndYpos = (volumeShapeRadius + volumeShapeRadius* sinf(M_PI/3 - M_PI/6 * endStrokeValue )) ;
    return CGPointMake(fabs(volumeEndXpos), fabs(volumeEndYpos));
}

- (CGRect)calculateVolumeGuideBoundsFromBounds:(CGRect)bounds{
    //make the frame
    float volumeShapeRadius = 1.0 + (bounds.size.height / 2);
    float volumeStarXpos = fabsf((volumeShapeRadius + volumeShapeRadius* cosf(M_PI /3))) ;
    float volumeStarYpos =  fabsf((volumeShapeRadius + volumeShapeRadius* sinf(M_PI /3))) ;
    float volumeEndYpos =  fabsf((volumeShapeRadius + volumeShapeRadius* sinf( M_PI/6))) ;
    
    float arcDist = (M_PI/6 - M_PI/3) / (2 *M_PI) * (2*M_PI * volumeShapeRadius) ;
    
    //xy size is needed
    CGRect returnValue = CGRectMake(volumeStarXpos, volumeStarYpos, fabs(arcDist),  fabs(volumeEndYpos - volumeStarYpos) ) ;
    
    return returnValue;
}

- (CGPathRef)createVolumeGuideFromBounds:(CGRect)boundRect {
   
    CGRect bounds = CGRectMake(0.0f, 0.0f, boundRect.size.width , boundRect.size.width );
    
    float volumeShapeRadius = 3 + (bounds.size.height / 2);
    UIBezierPath *volumeOutline = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)) radius:volumeShapeRadius startAngle:(M_PI /3) endAngle:(M_PI /6) clockwise:NO];
    
    return volumeOutline.CGPath;
    
    
}

- (CGPathRef)createVolumeWaveShape:(NSUInteger)waveCount{
    UIBezierPath *speakerWavePath = [UIBezierPath bezierPath];
    
    [speakerWavePath moveToPoint:CGPointMake(1.0f,  4.0f)];
    [speakerWavePath addQuadCurveToPoint:CGPointMake(1.0f,  7.0f) controlPoint:CGPointMake( 3.0f,  6.0f)];
    if (waveCount > 1) {
        [speakerWavePath moveToPoint:CGPointMake(2.0f, 2.0f)];
        [speakerWavePath addQuadCurveToPoint:CGPointMake(2.0f, 9.0f) controlPoint:CGPointMake(6.0f, 6.0f)];
    }
    if (waveCount > 2) {
        [speakerWavePath moveToPoint:CGPointMake( 3.0f, 0.0f )];
        [speakerWavePath addQuadCurveToPoint:CGPointMake( 3.0f, 11.0f) controlPoint:CGPointMake(9.0f,  6.0f)];
    }
    return speakerWavePath.CGPath;
}

- (CGPathRef)createVolumeShape{
    
    //draw speaker shape
    UIBezierPath *speakerPath = [UIBezierPath bezierPath];
    [speakerPath moveToPoint:CGPointMake(0.0f, 4.0f)] ;
    [speakerPath addLineToPoint:CGPointMake(0.0f, 7.0f)];
    [speakerPath addLineToPoint:CGPointMake(3.0f, 7.0f)];
    [speakerPath addLineToPoint:CGPointMake(7.0f, 11.0f)];
    [speakerPath addLineToPoint:CGPointMake(7.0f, 0.0f)];
    [speakerPath addLineToPoint:CGPointMake(3.0f, 4.0f)];
    [speakerPath addLineToPoint:CGPointMake(0.0f, 4.0f)];
    [speakerPath closePath];
    
    return speakerPath.CGPath;
}

- (float)calculatePadding{
    return (self.pathWidth + self.borderWidth  + self.innerSpace) ;
}

- (float)calculateWidthAndHeightValue{
    return  self.frame.size.width < self.frame.size.height ? self.frame.size.width : self.frame.size.height;
}

#pragma mark - public methods

- (void)setSongProgress:(float)songProgress updateFrequency:(float)updateInterval{

    if (self.animationSequence == 0 && songProgress >= 0) {
        [self.progressLayer setStrokeEnd:songProgress];
        CABasicAnimation *strokeEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeEndAnimation.duration = updateInterval;
        [strokeEndAnimation setFillMode:kCAFillModeForwards];
        strokeEndAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        strokeEndAnimation.removedOnCompletion = NO;
        strokeEndAnimation.fromValue = [NSNumber numberWithFloat:self.progress];
        strokeEndAnimation.toValue = [NSNumber numberWithFloat:songProgress];
        [self.progressLayer addAnimation:strokeEndAnimation forKey:@"progressPlayStatus"];
        self.progress = songProgress;
    }
}

- (void)switchAlbumImage:(UIImage*)image{
    self.albumImage = image;
   self.imageLayer.contents = (__bridge id)(image.CGImage);
}

- (void)setAlbumCoverImage:(UIImage*)coverImage{
    self.albumImage = coverImage;
    
    CAAnimation *scaledDownAnimation = [self.imageLayer animationForKey:@"scaledownimage"];
    if (scaledDownAnimation) {
        self.imageLayer.contents = (__bridge id)(coverImage.CGImage);
        [self cleanupAnimations];
        
    }else{
        [self processDiscChangeAnimation];
        
    }
    
}

- (void)setDefaultVolumeLevel:(float)toVolume{
    self.volumeLevel = toVolume;
}


#pragma mark -  disk Animations

- (void)processDiscChangeAnimation{
    self.animationSequence = 1;
    
    CAAnimation *scaledDownAnimation = [self.progressBackground animationForKey:@"scaledown"];
    if (!scaledDownAnimation) {
        CAKeyframeAnimation *scaledown = [self makeScaleDownAnimationWithDuration:0.7f usingTransform:self.progressBackground.transform];
        scaledown.delegate = (id)self;
        [self.progressBackground addAnimation:scaledown forKey:@"scaledown"];
        [self.progressLayer addAnimation:[self makeScaleDownAnimationWithDuration:0.7f usingTransform:self.progressLayer.transform] forKey:@"scaledownp"];
    }else{

        [self animateDiscChange];
    }
}


- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
    
    switch (self.animationSequence) {
        case 1:
            [self animateDiscChange];
            break;
        case 2:
            [self.imageLayer removeAnimationForKey:@"diskChangeAnimation" ];
            self.imageLayer.contents = (__bridge id)(self.albumImage.CGImage);
            [self.progressLayer removeAnimationForKey:@"progressPlayStatus"];
            [self.progressLayer setStrokeEnd:0.0f];
            self.progress = 0.0f;
            [self animateProgressLayerVisibile];
            break;
        case 3:
            [self cleanupAnimations];
            break;
        default:
            break;
    }
}

- (void)animateDiscChange{
    // use a group animation to smooth out the disk change. Essentially, flip the disk, change content, flip disk 180 degrees, flip disk back
    // whilst this smooths out the animation, we need to remove the animation
    // note the transform for the flip back - set to emulate a rotation so the start transform is fliped from the ending transform of the previous

    
    [self.imageLayer setZPosition:100.0f];
    
    self.animationSequence = 2;
    
    // firt part of disk rotation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.5f;
    // animation.duration = 5.0f;
    animation.beginTime = 0.0f;
    CATransform3D tfm = CATransform3DMakeRotation(M_PI/2.0f, 0.0f, -1.0f, 0.0f);
    tfm.m34 = 0.001f;
    tfm.m14 = -0.001f;
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation.toValue = [NSValue valueWithCATransform3D:tfm];
    
    // change the content
    CAKeyframeAnimation *contentChangeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    contentChangeAnimation.duration = 0.0f;
    contentChangeAnimation.beginTime = 0.5f;
     NSArray *contentsArray = @[(__bridge id)self.albumImage.CGImage];
    [contentChangeAnimation setValues:contentsArray];
    
    // animate disc change to completion
    CABasicAnimation *reverseAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    reverseAnimation.duration = 0.5f;
    reverseAnimation.beginTime = 0.5f;
    CATransform3D rtfm = CATransform3DMakeRotation(3.0f*M_PI/2.0f, 0.0f, 1.0f, 0.0f);
     rtfm.m34 = - 0.001f;
    rtfm.m14 = 0.001f;
    reverseAnimation.fromValue =  [NSValue valueWithCATransform3D:rtfm];
    reverseAnimation.toValue =  [NSValue valueWithCATransform3D:CATransform3DIdentity];
    
    //group the animations
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    group.duration = 1.0f;
    group.fillMode =  kCAFillModeForwards;
    group.removedOnCompletion = NO;
    group.delegate = (id)self;
    [group setAnimations:[NSArray arrayWithObjects:animation, contentChangeAnimation, reverseAnimation, nil]];
    
    [self.imageLayer addAnimation:group forKey:@"diskChangeAnimation"];
}


- (void)animateProgressLayerVisibile{
    self.animationSequence = 3;
    CAKeyframeAnimation *scaleUp = [self makeScaleUpAnimationWithDuration:0.7f usingTransform:self.progressBackground.transform];
    scaleUp.delegate = (id) self;
    [self.progressBackground addAnimation:scaleUp forKey:@"scaleup"];
    [self.progressLayer addAnimation:[self makeScaleUpAnimationWithDuration:0.7f usingTransform:self.progressLayer.transform] forKey:@"scaleup"];
    
}


- (CAKeyframeAnimation*)makeScaleDownAnimationWithDuration:(float)duration usingTransform:(CATransform3D) trfm{
    
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.duration = duration;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    NSArray *scaleValues =  @[[NSValue valueWithCATransform3D:CATransform3DScale(trfm, 1.0f, 1.0f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 1.05f, 1.05f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.9f, 0.9f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.6f, 0.6f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.2f, 0.2f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.0f, 0.0f, 1.0f)]];
    [scaleAnimation setValues:scaleValues];
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.removedOnCompletion = NO;
    return scaleAnimation;
}

- (CAKeyframeAnimation*)makeScaleUpAnimationWithDuration:(float)duration usingTransform:(CATransform3D) trfm{
    
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.duration = duration;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    NSArray *scaleValues =  @[[NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.0f, 0.0f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.2f, 0.2f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.6f, 0.6f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 0.9f, 0.9f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 1.05f, 1.05f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DScale(trfm, 1.0f, 1.0f, 1.0f)]];
    
    
    [scaleAnimation setValues:scaleValues];
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.removedOnCompletion = NO;
    return scaleAnimation;
}



- (void)cleanupAnimations{
    if ([self.playerViewDelegate respondsToSelector:@selector(finishedDiscChangeAnimation)]) {
        [self.playerViewDelegate  finishedDiscChangeAnimation];
    }
    
    [self.progressLayer removeAnimationForKey:@"scaledownp"];
    [self.progressBackground removeAnimationForKey:@"scaledown"];
    [self.progressLayer removeAnimationForKey:@"scaleup"];
    [self.progressBackground removeAnimationForKey:@"scaleup"];
    
    self.animationSequence = 0;

}

- (void)setVolumeProgressSlider:(float)volumeLevel{

    [CATransaction setDisableActions:YES];
    self.volumeProgressShapeLayer.strokeEnd = volumeLevel;
    self.volumeKnobShapeLayer.position =  [self calculateXYPointsForVolumeGuideEndFromBounds:self.progressBackground.frame distanceValue:volumeLevel];
    if ([self.playerViewDelegate respondsToSelector:@selector(adjustedVolume:)]) {
        [self.playerViewDelegate adjustedVolume:volumeLevel];
    }
    
    if (volumeLevel >0.8f) {
        self.volumeWavesShapeLayer.path = [self createVolumeWaveShape:3];
    }else if (volumeLevel > 0.4f){
        self.volumeWavesShapeLayer.path = [self createVolumeWaveShape:2];
    }else if (volumeLevel > 0.01f){
        self.volumeWavesShapeLayer.path = [self createVolumeWaveShape:1];
    }else if (volumeLevel < 0.01f){
        self.volumeWavesShapeLayer.path = nil;
    }
}

- (CGPathRef)makeMenuLinesConstrainedToBounds:(CGRect)boundsRect{
    
    float lineHeight = floorf(boundsRect.size.height / 6);
    
    UIBezierPath *menuPath = [UIBezierPath bezierPath];
    [menuPath moveToPoint:CGPointMake(0.0f, 0.0f)];
    [menuPath addLineToPoint:CGPointMake(boundsRect.size.width * 0.2f, 0.0f)];
    [menuPath moveToPoint:CGPointMake(boundsRect.size.width * 0.3f, 0.0f)];
    [menuPath addLineToPoint:CGPointMake(boundsRect.size.width, 0.0f)];
    
    [menuPath moveToPoint:CGPointMake(0.0f, lineHeight * 2)];
    [menuPath addLineToPoint:CGPointMake(boundsRect.size.width * 0.2f, lineHeight *2)];
    [menuPath moveToPoint:CGPointMake(boundsRect.size.width * 0.3f, lineHeight * 2)];
    [menuPath addLineToPoint:CGPointMake(boundsRect.size.width,  lineHeight * 2)];
    
    [menuPath moveToPoint:CGPointMake(0.0f, lineHeight * 4)];
    [menuPath addLineToPoint:CGPointMake(boundsRect.size.width * 0.2f, lineHeight *4)];
    [menuPath moveToPoint:CGPointMake(boundsRect.size.width * 0.3f, lineHeight * 4)];
    [menuPath addLineToPoint:CGPointMake(boundsRect.size.width,  lineHeight * 4)];
    
    return menuPath.CGPath;
}

- (CGPathRef)makeGraphicEQIconConstrindToBounds:(CGRect)boundsRect{
    float lineWidth = floorf(boundsRect.size.width / 10);
    UIBezierPath *graphicEQPath = [UIBezierPath bezierPath];
    
    [graphicEQPath moveToPoint:CGPointMake(0.0f, boundsRect.size.height )];
    [graphicEQPath addLineToPoint:CGPointMake(0.0f, boundsRect.size.height * 0.6f)];
    
    [graphicEQPath moveToPoint:CGPointMake(lineWidth * 2, boundsRect.size.height)];
    [graphicEQPath addLineToPoint:CGPointMake(lineWidth * 2, boundsRect.size.height * 0.2f)];

    [graphicEQPath moveToPoint:CGPointMake(lineWidth * 4,boundsRect.size.height)];
    [graphicEQPath addLineToPoint:CGPointMake(lineWidth * 4, boundsRect.size.height * 0.4f)];
    
    [graphicEQPath moveToPoint:CGPointMake(lineWidth * 6, boundsRect.size.height)];
    [graphicEQPath addLineToPoint:CGPointMake(lineWidth * 6, boundsRect.size.height * 0.7f)];
    
    [graphicEQPath moveToPoint:CGPointMake(lineWidth * 8, boundsRect.size.height)];
    [graphicEQPath addLineToPoint:CGPointMake(lineWidth * 8, boundsRect.size.height * 0.5f)];
    
    return graphicEQPath.CGPath;
    
}

#pragma mark - Pan Gesture and Events
- (void)setupPanGesture{
    if(!self.panGesture){
        self.panGesture = [[UIPanGestureRecognizer alloc]
                           initWithTarget:self action:@selector(handlePanGesture:)];
        [self addGestureRecognizer:self.panGesture];
        [self.panGesture setDelegate:self];
    }
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer {
    
    CGPoint touchPoint = [recognizer locationInView:self];
    
    if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        CGPoint touchPointInGraphicEQMenuLayer = [ self.graphicEQMenuShapeLayer.superlayer convertPoint:touchPoint toLayer:self.graphicEQMenuShapeLayer];
        if ([self.graphicEQMenuShapeLayer containsPoint:touchPointInGraphicEQMenuLayer]){
            self.menuTouchLocation = MDProgresViewEQ;
            return YES;
        }
        CGPoint touchPointInMenuLayer = [self.menuShapeLayer.superlayer convertPoint:touchPoint toLayer:self.menuShapeLayer];
        if ([self.menuShapeLayer containsPoint:touchPointInMenuLayer]) {
            self.menuTouchLocation = MDProgressViewMenu;
            self.menuShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
            self.menuShapeLayer.path = [self makeMenuLinesConstrainedToBounds:self.menuShapeLayer.frame];
            [self setNeedsDisplayInRect:self.menuShapeLayer.frame];
            [CATransaction flush];
            return YES;
        }
    }
    
    
    if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint touchPointInVolumeLayer =[self.volumeContainerLayer.superlayer convertPoint:touchPoint toLayer:self.volumeContainerLayer];
        if ([self.volumeContainerLayer containsPoint:touchPointInVolumeLayer]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (!([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) ) {
        return NO;
    }
    return YES;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateBegan){
        self.gestureCalcPoint = CGPointZero;
    }
    
    CGPoint velocity = [recognizer translationInView:self];
    
    self.volumeLevel +=  (((velocity.x - self.gestureCalcPoint.x) + ((velocity.y - self.gestureCalcPoint.y) *-1) /2) /self.volumeContainerLayer.frame.size.width);
    self.volumeLevel = MAX(0.0f, MIN(1.0f, self.volumeLevel));
    [self setVolumeProgressSlider:self.volumeLevel ];
    self.gestureCalcPoint = velocity;
}


#pragma mark - Tap Gesture and Events
- (void)setupTapGesture{
    if(!self.tapGesture){
        self.tapGesture = [[UITapGestureRecognizer alloc]
                           initWithTarget:self action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:self.tapGesture];
        [self.tapGesture setDelegate:self];
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer {
    if ((self.playerViewDelegate) && ([self.playerViewDelegate respondsToSelector:@selector(didReceivedTouchOnMenu:)])) {
        [self.playerViewDelegate didReceivedTouchOnMenu:self.menuTouchLocation];
        if (self.menuTouchLocation == MDProgresViewEQ) {
            CAAnimation *scaledDownAnimation = [self.imageLayer animationForKey:@"scaledownimage"];
            if (scaledDownAnimation ) {
                [self.imageLayer removeAnimationForKey:@"scaledownimage"];
                [self.imageLayer addAnimation:[self makeScaleUpAnimationWithDuration:0.7f usingTransform:self.imageLayer.transform] forKey:@"scaleupimage"];
            }else  {
                [self.imageLayer addAnimation:[self makeScaleDownAnimationWithDuration:0.7f usingTransform:self.imageLayer.transform] forKey:@"scaledownimage"];
            }
            [self scaleEQAnalayzerDisplay];
        }else if (self.menuTouchLocation == MDProgressViewMenu){
            self.menuShapeLayer.strokeColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.3f].CGColor;
            self.menuShapeLayer.path = [self makeMenuLinesConstrainedToBounds:self.menuShapeLayer.frame];

        }
        
    }
}

-(void) replaceDefaultSPAnalyzerWithBarCount : (UInt32) barCount{
    // if the number of bars received is not equal to the default 
    self.EQAnalyzerDisplayLayer =  [[MDGraphicEqualizerDisplayLayer alloc]initWithNumberOfBars:barCount];
    [self.layer addSublayer:self.EQAnalyzerDisplayLayer];
}

-(void)scaleEQAnalayzerDisplay{
    CAAnimation *scaleDownAnimation = [self.EQAnalyzerDisplayLayer animationForKey:@"scaledowneq"];
    if (scaleDownAnimation) {
        [self.EQAnalyzerDisplayLayer removeAnimationForKey:@"scaledowneq"];
        [self.EQAnalyzerDisplayLayer addAnimation:[self makeScaleUpAnimationWithDuration:0.7f usingTransform:self.EQAnalyzerDisplayLayer.transform] forKey:@"scaleupeq"];
         self.graphicEQMenuShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
         self.graphicEQMenuShapeLayer.path = [self makeGraphicEQIconConstrindToBounds:self.graphicEQMenuShapeLayer.frame];
    }else{
        [self.EQAnalyzerDisplayLayer addAnimation:[self makeScaleDownAnimationWithDuration:0.7f usingTransform:self.EQAnalyzerDisplayLayer.transform] forKey:@"scaledowneq"];
        self.graphicEQMenuShapeLayer.strokeColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:0.3f].CGColor;
        self.graphicEQMenuShapeLayer.path = [self makeGraphicEQIconConstrindToBounds:self.graphicEQMenuShapeLayer.frame];
    }
}

- (void)updateSpectrumDisplay:(NSMutableArray*) frequencyArray numberOfElements:(UInt32)elementsAvailable{
    if (self.EQAnalyzerDisplayLayer.displayBarCount != elementsAvailable) {
        [self replaceDefaultSPAnalyzerWithBarCount:elementsAvailable];

    }
    [self.EQAnalyzerDisplayLayer updateDisplayBars:frequencyArray];
}

- (void)clearSpectrumDisplay{
    NSMutableArray *clearArray = [NSMutableArray new];
    NSNumber *zeroValue = [NSNumber numberWithDouble:-128.00];
    for (int i = 0; i < self.EQAnalyzerDisplayLayer.displayBarCount; i++) {
        [clearArray addObject:zeroValue];
    }
    [self.EQAnalyzerDisplayLayer updateDisplayBars:clearArray];
}

@end
