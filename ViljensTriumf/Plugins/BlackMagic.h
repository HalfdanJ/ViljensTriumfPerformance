#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import "DeckLinkAPI.h"
#import "DecklinkCallback.h"

class DeckLinkController;
@interface BlackMagic : ofPlugin {
	DeckLinkController*				deckLinkController;
    
    std::vector<IDeckLink*>			deviceList;
    
    
    IDeckLinkInput  *  deckLinkInputs[3];
    DecklinkCallback * callbacks[3];
    
    ofImage currentFrames[3];
}

@end
