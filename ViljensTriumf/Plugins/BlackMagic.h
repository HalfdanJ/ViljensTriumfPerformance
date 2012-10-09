#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import "BlackMagicController.h"

#import "DeinterlaceFilter.h"
#import <QTKit/QTKit.h>

#define MOVIE_LENGTH 7200

class DeckLinkController;
@interface BlackMagic : ofPlugin {
    BlackMagicController * blackMagicController;
    
//    ofVideoGrabber * grabber[3];
    
    int outSelector;
    

    ofImage currentFrames[3];
    CIImage * currentCIImage[3];
    ofImage movieRecording[MOVIE_LENGTH];
    
    int playbackIndex;
    int millisAtLastFramePlayback;
    
    bool recordMovie;
    int millisAtLastFrameRecord;
    int recordIndex;
    
    
    /*    ofxShader * bwShader;
     ofxShader * deinterlace;
     */

        
    CIContext * ciContextMain; //Context for main output
    CIContext * ciContextControl; //Context for control gl view
    CIContext * ciContext; //Dynamic switched context (main/control)
    
    CIImage * renderImage;
    bool renderImageUpdated;

    CIFilter * blurFilter;
    DeinterlaceFilter * deinterlaceFilter;
    CIFilter * colorControlsFilter;
    CIFilter * gammaAdjustFilter;
    CIFilter * toneCurveFilter;
    
    QTMovie *mMovie;
    QTVisualContextRef	movieTextureContext;
    CVOpenGLTextureRef  movieCurrentFrame;
    
    NSImage * recordImage;

//    CIImage * movie[1000];

}

@end
