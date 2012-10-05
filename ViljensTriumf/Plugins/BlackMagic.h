#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import "BlackMagicController.h"

class DeckLinkController;
@interface BlackMagic : ofPlugin {
    BlackMagicController * blackMagicController;
    
    
    ofImage currentFrames[3];
    
    int outSelector;
    
//    ofImage
}

@end
