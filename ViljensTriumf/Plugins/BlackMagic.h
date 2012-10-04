#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import "DeckLinkAPI.h"
#import "DecklinkCallback.h"
#import "ofxShader.h"

#define MOVIE_LENGTH 7200

class DeckLinkController;
@interface BlackMagic : ofPlugin {
	DeckLinkController*				deckLinkController;
    
    std::vector<IDeckLink*>			deviceList;
    
    
    IDeckLinkInput  *  deckLinkInputs[3];
    DecklinkCallback * callbacks[3];
    
    ofImage currentFrames[3];
    
    int outSelector;
    
    ofImage movieRecording[MOVIE_LENGTH];

    int playbackIndex;
    int millisAtLastFramePlayback;
    
    ofxShader * bwShader;
    ofxShader * deinterlace;
    
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
