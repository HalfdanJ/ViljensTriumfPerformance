#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import "BlackMagicController.h"

#import "DeinterlaceFilter.h"
#import "ChromaFilter.h"

#import <QTKit/QTKit.h>

#import "MavController.h"

#define NUM_SELECTORS 3

class DeckLinkController;
@interface BlackMagic : ofPlugin {
    BlackMagicController * blackMagicController;

    int outSelector;
    
    ofImage currentFrames[3];
    CIImage * currentCIImage[3];
    
    bool recordMovie;
    int millisAtLastFrameRecord;
    
    
    
    /*    ofxShader * bwShader;
     */
    
    CIContext * ciContextMain; //Context for main output
    CIContext * ciContextControl; //Context for main output
    CIContext * ciContext; //Dynamic switched context (main/control)

    CIFilter * blurFilter;
    DeinterlaceFilter * deinterlaceFilter;
    CIFilter * colorControlsFilter;
    CIFilter * gammaAdjustFilter;
    CIFilter * toneCurveFilter;
    ChromaFilter * chromaFilter;
    
    QTMovie *mMovie;
    QTVisualContextRef	movieTextureContext;
    CVOpenGLTextureRef  movieCurrentFrame;
    
    NSImage * recordImage;
    
    MavController * mavController;

}

@end
