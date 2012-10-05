#import "BlackMagic.h"
#import <ofxCocoaPlugins/Keystoner.h>
#import <OpenGL/CGLRenderers.h>

@implementation BlackMagic

-(void)initPlugin{
    [self addPropF:@"saturation"];
    [self addPropF:@"brightness"];
    [[self addPropF:@"contrast"] setMaxValue:1.5];

    [[self addPropF:@"gamma"] setMaxValue:1.5];

/*[self addPropF:@"curvep1"];
    [self addPropF:@"curvep2"];
    [self addPropF:@"curvep3"];
    [self addPropF:@"curvep4"];
    [self addPropF:@"curvep5"];*/

    
    //    [self addPropF:@"blur"];
    [self addPropB:@"deinterlace"];

    
    blackMagicController = [[BlackMagicController alloc] init];
    [blackMagicController initDecklink];

    
}

//
//----------------
//


-(void)setup{

    glewInit();
    
/*    bwShader = new ofxShader();
    bwShader->setup("/Users/jonas/Development/ViljensTriumf/ViljensTriumf/Plugins/shaders/bwShader");

    deinterlace = new ofxShader();
    deinterlace->setup("/Users/jonas/Development/ViljensTriumf/ViljensTriumf/Plugins/shaders/deinterlace");
*/
    
    for(int i=0;i<MOVIE_LENGTH;i++){
        
    }
    

    
    blurFilter = [[CIFilter filterWithName:@"CIGaussianBlur"] retain];
    [blurFilter setDefaults];

    
    colorControlsFilter = [[CIFilter filterWithName:@"CIColorControls"] retain];
    [colorControlsFilter setDefaults];

    gammaAdjustFilter = [[CIFilter filterWithName:@"CIGammaAdjust"] retain];
    [gammaAdjustFilter setDefaults];
    
    toneCurveFilter = [[CIFilter filterWithName:@"CIToneCurve"] retain];
    [toneCurveFilter setDefaults];
    
    deinterlaceFilter = [[DeinterlaceFilter alloc] init];
    [deinterlaceFilter setDefaults];
    
    CGLContextObj  contextGl = CGLContextObj([[[[[globalController viewManager] glViews] objectAtIndex:0] openGLContext] CGLContextObj]);
	CGLPixelFormatObj pixelformatGl = CGLPixelFormatObj([[[[[globalController viewManager] glViews] objectAtIndex:0] pixelFormat] CGLPixelFormatObj]);
    ciContextMain = [CIContext contextWithCGLContext:contextGl pixelFormat:pixelformatGl  colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];

}

//
//----------------
//








-(CIImage*) imageForSelector:(int)selector{
    if(selector == 0){
        return nil;
    }
    if(selector > 0 && selector <= 3){
        return currentFrames[selector-1];
    }
 /*   if(selector == 4){
        if(millisAtLastFramePlayback < ofGetElapsedTimeMillis() - 40){
            millisAtLastFramePlayback = ofGetElapsedTimeMillis();
            playbackIndex++;
            if(recordIndex <= playbackIndex){
                playbackIndex = recordIndex-1;
            }
        }
        return &movieRecording[playbackIndex];
    }*/
}

-(void)update:(NSDictionary *)drawingInformation{
    for(int i=0;i<3;i++){
        DecklinkCallback * callback = [blackMagicController callbacks:i];
        if(callback->newFrame){
                callback->newFrame = false;
                int w = callback->w;
                int h = callback->h;
                
                
                
                if(currentFrames[i]){
                    [currentFrames[i] release];
                }
                
            pthread_mutex_lock(&callback->mutex);
            unsigned char * bytes = callback->bytes;

                NSData * data = [[NSData dataWithBytes:bytes length:w*h*4] autorelease];
                // NSLog(@"%i",[data retainCount]);
            
            pthread_mutex_unlock(&callback->mutex);

                CGColorSpace * space = CGColorSpaceCreateDeviceRGB();
                currentFrames[i] = [CIImage imageWithBitmapData:data bytesPerRow:w*4 size:CGSizeMake(w, h) format:kCIFormatARGB8 colorSpace:space];
            
                [data release];
                data = nil;

        }
    }
    
/*    if(recordMovie){
        if(millisAtLastFrameRecord < ofGetElapsedTimeMillis() - 40){
            millisAtLastFrameRecord = ofGetElapsedTimeMillis();
            ofImage * img = [self imageForSelector:outSelector];
            if(img != nil && outSelector != 4){
                //                movieRecording[recordIndex]
                movieRecording[recordIndex++] = *img;
                
                NSLog(@"Rec... %i",int( (float)100.0*recordIndex/MOVIE_LENGTH) );
                if(recordIndex == MOVIE_LENGTH)
                    recordMovie = false;

            }
        }
    }*/
}


//
//----------------
//
-(CIImage*) createCIImageFromTexture:(GLint)tex size:(NSSize)size{
   // NSLog(@"Create CI Image");
    CIImage * image = [CIImage imageWithTexture:tex size:CGSizeMake(size.width, size.height) flipped:NO colorSpace:CGColorSpaceCreateDeviceRGB()];
    //  NSURL * url = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@%@", [engine assetDir],[self assetString]] isDirectory:NO];
    //    CIImage * image = [CIImage imageWithContentsOfURL:url];
    return image;
}

-(CIImage*) filterCIImage:(CIImage*)inputImage{
    //   [resizeFilter setValue:inputImage forKey:@"inputImage"];
    // [depthBlurFilter setValue:[resizeFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
   
    CIImage * _outputImage = inputImage;
    
    if(PropB(@"deinterlace")){
    [deinterlaceFilter setInputImage:_outputImage];
    _outputImage = [deinterlaceFilter valueForKey:@"outputImage"];
    }
    
//    [blurFilter setValue:[NSNumber numberWithFloat:PropF(@"blur")] forKey:@"inputRadius"];
//    [blurFilter setValue:_outputImage forKey:@"inputImage"];
//    _outputImage = [blurFilter valueForKey:@"outputImage"];
//    
    [colorControlsFilter setValue:[NSNumber numberWithFloat:PropF(@"saturation")] forKey:@"inputSaturation"];
    [colorControlsFilter setValue:[NSNumber numberWithFloat:PropF(@"contrast")] forKey:@"inputContrast"];
    [colorControlsFilter setValue:[NSNumber numberWithFloat:PropF(@"brightness")] forKey:@"inputBrightness"];
    [colorControlsFilter setValue:_outputImage forKey:@"inputImage"];
    _outputImage = [colorControlsFilter valueForKey:@"outputImage"];
    
    
    [gammaAdjustFilter setValue:[NSNumber numberWithFloat:PropF(@"gamma")] forKey:@"inputPower"];
    [gammaAdjustFilter setValue:_outputImage forKey:@"inputImage"];
    _outputImage = [gammaAdjustFilter valueForKey:@"outputImage"];
    
   /* [toneCurveFilter setValue:[NSNumber numberWithFloat:PropF(@"curvep1")] forKey:@"inputPoint0"];
    [toneCurveFilter setValue:[NSNumber numberWithFloat:PropF(@"curvep2")] forKey:@"inputPoint1"];
    [toneCurveFilter setValue:[NSNumber numberWithFloat:PropF(@"curvep3")] forKey:@"inputPoint2"];
    [toneCurveFilter setValue:[NSNumber numberWithFloat:PropF(@"curvep4")] forKey:@"inputPoint3"];
    [toneCurveFilter setValue:[CIVector numberWithFloat:PropF(@"curvep5")] forKey:@"inputPoint4"];
    [toneCurveFilter setValue:_outputImage forKey:@"inputImage"];
    _outputImage = [toneCurveFilter valueForKey:@"outputImage"];*/
    
    
    return _outputImage;
}


-(void) render{
    

    
    
       
    ofFill();
    ofSetColor(255, 255, 255);
    
  /*  bwShader->begin();
    bwShader->setUniform("min", PropF(@"min"));
    bwShader->setUniform("max", PropF(@"max"));*/
    
   // deinterlace->begin();
   // deinterlace->setUniform("texcoord0", ofGetFrameNum()%2, 0);
    //     deinterlace->setUniform("texdim0", 720, 576);
    
    if(outSelector == 0){
        ofSetColor(0, 0, 0);
        ofRect(0, 0, 1, 1);
    }
    /* if(outSelector == 2){
     glScaled(1.333,1,1);
     [self imageForSelector:outSelector]->draw(0,0,1,1);
     }
     else */
    if(outSelector > 0 && outSelector <= 4){
        // CIImage * outputImage = [self createCIImageFromTexture:[self imageForSelector:outSelector]->getTextureReference().getTextureData().textureID size:NSMakeSize([self imageForSelector:outSelector]->getWidth(), [self imageForSelector:outSelector]->getHeight())];
        
        CIImage * outputImage = [self imageForSelector:outSelector];
        if(outputImage){
            outputImage = [self filterCIImage:outputImage];
            
            float h = [outputImage extent].size.height;
            glScaled(1.0/[outputImage extent].size.width, -1.0/h, 1);
            //glScaled(1.0/720, 10/576.0, 1);
            [ciContext drawImage:outputImage
                         atPoint:CGPointMake(0,-h) // use integer coordinates to avoid interpolation
                        fromRect:[outputImage extent]];
        }
        outputImage = nil;
        
        //[self imageForSelector:outSelector]->draw(0,0,1,1);
    }
    //    bwShader->end();
    // deinterlace->end();
}

-(void)draw:(NSDictionary *)drawingInformation{
    ciContext = ciContextMain;
    
 //   shader->begin();
    [self render];
    
 //   shader->end();

}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{
    if(!ciContextControl){
    CGLContextObj  contextGl =  CGLGetCurrentContext();
	CGLPixelFormatObj pixelformatGl = CGLPixelFormatObj([[[[[globalController viewManager] glViews] objectAtIndex:0] pixelFormat] CGLPixelFormatObj]);
    ciContextControl = [CIContext contextWithCGLContext:contextGl pixelFormat:pixelformatGl  colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];
    }
    ciContext = ciContextControl;

    
    
    ofBackground(255, 255, 255);
    ofSetColor(255, 255, 255);

    float w = ofGetWidth();
    float h = ofGetHeight();
    
    float mW = w/3.0;
    float mH = mW * 3.0/4.0;
 
    for(int i=0;i<3;i++){
 //       currentFrames[i].draw(i*mW,0,mW,mH);
    }

    ofTranslate(0,mH+30);
    ofScale(mW*3,mH*3);
  //  [self render];

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
        case 86:
            recordMovie = !recordMovie;
            recordIndex = 0;
            break;
        case 87:
            recordMovie = false;
            outSelector = 4;
            playbackIndex = 0;
            break;
            
        default:
            break;
    }
}
@end
