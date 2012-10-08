#include "Plugin.h"
#import <QTKit/QTKit.h>
#import <QuartzCore/QuartzCore.h>

#import "DeckLinkAPI.h"
#include "ofxQTKitVideoGrabber.h"
#import "TimeCodeOverlay.h"
#include "ofxOsc.h"
#import <Quartz/Quartz.h>
#include "Chromakey.h"

@interface SubtitleItem : NSObject
{
    NSString * line1;
    NSString * line2;
    
}

@property (readwrite) NSString * line1;
@property (readwrite) NSString * line2;

@end


@interface Blackmagic : ofPlugin {
    //QTKitVideoGrabber * grabber[3];
    ofVideoGrabber * grabber[3];
    
    int selectedCam;
    int fadeTo;
    float fade;
    
    CIContext                       *ciContext;
    CIContext                       *ciControlContext;
    QCRenderer                      *qcRenderer;
    
    CIFilter                        *colorCorrectionFilter; // hue saturation brightness control through one CI filter
    CIFilter                        *gloomFilter;   // hue saturation brightness control through one CI filter
    CIFilter                        *exposureFilter;
    CIFilter                        *dissolveFilter;
    CIFilter                        *atopFilter;
    CIFilter                        *chromaFilter;
    
    CGRect      imageRect;
    
    CIImage     *outputImage;
    
    IBOutlet NSImageView * imageView1;
    IBOutlet NSImageView * imageView2;
    IBOutlet NSImageView * imageView3;
    IBOutlet NSImageView * imageView4;
    IBOutlet NSImageView * imageView5;
    
    IBOutlet NSColorWell * chromaColor;
    
    CIImage * ciPhotos[10];
    NSURL * photosUrl[10];
    
    CIImage * titles[10];
    NSURL * titleUrl[10];
    
    CIImage * outro[15];
    NSURL * outroUrl[15];
    
    CIImage * lawyer[2];
    CIImage * porche;
    
    
    ofSerial * serial;
    ofSerial * serialMatrix;
    
    int titleImage;
    float titleFade;
    
    int outroImage;
    float outroFade;
    
    
    TimeCodeOverlay     *timeCodeOverlay;
    TimeCodeOverlay     *timeCodeOverlay2;
    
    TimeCodeOverlay     *clock;
    TimeCodeOverlay     *message;
    TimeCodeOverlay     *countdown;
    TimeCodeOverlay     *countdownMsg;
    
    CIImage * behindScene;
    
    NSString * subtext1;
    NSString * subtext2;
    NSMutableArray * subarray;
    
    BOOL blackSubtitle;
    BOOL clockVisible;
    BOOL behindSceneOn;
    int countdownInt;
    long countdownStart;
    
    ofxOscReceiver * subreceiver;
    
    QTMovie *movie;
    QTVisualContextRef      textureContext;
    CVOpenGLTextureRef  currentFrame;
    
}

@property (readonly) CIFilter *colorCorrectionFilter;
@property (readonly) CIFilter *gloomFilter;
@property (readonly) CIFilter *exposureFilter;

-(float) alpha:(int)n;
-(void) setAlpha:(int)n to:(float)v;
@end


@interface MixerView : NSView
{
    IBOutlet Blackmagic * plugin;
}


@end