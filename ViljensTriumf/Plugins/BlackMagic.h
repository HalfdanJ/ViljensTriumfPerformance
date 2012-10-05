#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import "BlackMagicController.h"
#define MOVIE_LENGTH 7200

class DeckLinkController;
@interface BlackMagic : ofPlugin {
    BlackMagicController * blackMagicController;
    
    
    ofImage currentFrames[3];
    
    int outSelector;
    
    ofImage movieRecording[MOVIE_LENGTH];

    int playbackIndex;
    int millisAtLastFramePlayback;
    
/*    ofxShader * bwShader;
    ofxShader * deinterlace;
  */
    
    bool recordMovie;
    int millisAtLastFrameRecord;
    int recordIndex;
    
    CIContext * ciContextMain;
    CIContext * ciContextControl;
    CIContext * ciContext;
    
    CIFilter * blurFilter;
    CIFilter * deinterlaceFilter;

}

@end
