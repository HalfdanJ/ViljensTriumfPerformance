#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import "BlackMagicController.h"

#import "DeinterlaceFilter.h"

#define MOVIE_LENGTH 7200

class DeckLinkController;
@interface BlackMagic : ofPlugin {
    BlackMagicController * blackMagicController;
    
    int outSelector;

    CIImage * currentFrames[3];
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
    
    CIFilter * blurFilter;
    DeinterlaceFilter * deinterlaceFilter;
    CIFilter * colorControlsFilter;
    CIFilter * gammaAdjustFilter;
    CIFilter * toneCurveFilter;
}

@end
