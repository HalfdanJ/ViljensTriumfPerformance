#import "BlackMagic.h"
#import <ofxCocoaPlugins/Keystoner.h>
#import "ofxShader.h"
#import <OpenGL/CGLRenderers.h>

@implementation BlackMagic

-(void)initPlugin{
    [self addPropF:@"whiteBack"];
    [self addPropF:@"whiteFront"];
    [self addPropF:@"grovKalibrering"];
    
    blackMagicController = [[BlackMagicController alloc] init];
    [blackMagicController initDecklink];
    
}

//
//----------------
//


-(void)setup{
/*    [[NSBundle mainBundle] pathForResource:@"colorCorrectShader" ofType:@"vert"];
    ofxShader * shader = new ofxShader();
    shader->setup("test");    */
}

//
//----------------
//




-(void)update:(NSDictionary *)drawingInformation{
    for(int i=0;i<3;i++){
        DecklinkCallback * callback = [blackMagicController callbacks:i];
        if(callback->newFrame){
            callback->newFrame = false;
            int w = callback->w;
            int h = callback->h;
            
            if(currentFrames[i].width != w){
                currentFrames[i].allocate(w, h, OF_IMAGE_COLOR);
            }
            
            unsigned char * bytes = callback->bytes;
            currentFrames[i].setFromPixels(bytes, w, h, OF_IMAGE_COLOR);
        }
    }
}


//
//----------------
//

-(void) render{
    ofFill();
    ofSetColor(255, 255, 255);
    if(outSelector == 0){
        ofSetColor(0, 0, 0);
        ofRect(0, 0, 1, 1);
    }
    if(outSelector > 0 && outSelector <= 3){
        currentFrames[outSelector-1].draw(0,0,1,1);
    }
}

-(void)draw:(NSDictionary *)drawingInformation{

    
 //   shader->begin();
    [self render];
    
 //   shader->end();

}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{
    ofBackground(255, 255, 255);
    float w = ofGetWidth();
    float h = ofGetHeight();
    
    float mW = w/3.0;
    float mH = mW * 3.0/4.0;
 
    for(int i=0;i<3;i++){
        currentFrames[i].draw(i*mW,0,mW,mH);
    }

    ofTranslate(0,mH+30);
    ofScale(mW*3,mH*3);
    [self render];

}

-(void)controlKeyPressed:(int)key modifier:(int)modifier{
//    NSLog(@"%i",key);
    switch (key) {
        case 82:
            outSelector = 0;
            break;

        case 83:
            outSelector = 1;
            break;
        case 84:
            outSelector = 2;
            break;
        case 85:
            outSelector = 3;
            break;
            
        default:
            break;
    }
}
@end
