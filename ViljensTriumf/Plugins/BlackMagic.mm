#import "BlackMagic.h"
#import <ofxCocoaPlugins/Keystoner.h>
#import <OpenGL/CGLRenderers.h>

@implementation BlackMagic

-(void)initPlugin{
    [self addPropF:@"saturation"];
    [self addPropF:@"brightness"];
    [[self addPropF:@"contrast"] setMaxValue:1.5];
    
    [[self addPropF:@"gamma"] setMaxValue:1.5];
    
    
    [[self addPropF:@"chromaMin"] setMaxValue:360];
    [[self addPropF:@"chromaMax"] setMaxValue:360];
    [self addPropB:@"chromaKey"];
    /*[self addPropF:@"curvep1"];
     [self addPropF:@"curvep2"];
     [self addPropF:@"curvep3"];
     [self addPropF:@"curvep4"];
     [self addPropF:@"curvep5"];*/
    
    
    //    [self addPropF:@"blur"];
    [self addPropB:@"deinterlace"];
    
    
    blackMagicController = [[BlackMagicController alloc] init];
    [blackMagicController initDecklink];
    
    
    
    
    [NSEvent addLocalMonitorForEventsMatchingMask:(NSKeyDownMask) handler:^(NSEvent *incomingEvent) {
		NSLog(@"Events: %@",incomingEvent);
		
        //	if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
/*if( == 83){
				fadeTo = 0;
				fade = 0;
			} else {
				selectedCam = 0;
			}
		}*/
        switch ([incomingEvent keyCode]) {
            case 82:
                outSelector = 0;

                break;
                
            case 83:
                outSelector = 1;
                /*   serial.writeByte('1');
                 serial.writeByte('*');
                 serial.writeByte('4');
                 serial.writeByte('!');*/
                break;
            case 84:
                outSelector = 2;
                /*            serial.writeByte('2');
                 serial.writeByte('*');
                 serial.writeByte('4');
                 serial.writeByte('!');*/
                break;
            case 85:
                outSelector = 3;
                /*            serial.writeByte('3');
                 serial.writeByte('*');
                 serial.writeByte('4');
                 serial.writeByte('!');*/
                break;
            case 86:
                millisAtLastFrameRecord = ofGetElapsedTimeMillis();
                recordMovie = !recordMovie;
                
                if(!recordMovie){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSError * outError = nil;
                        if(![mMovie writeToFile:@"/Users/jonas/Desktop/test.mov" withAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:QTMovieFlatten] error:&outError]){
                            NSLog(@"Could not write %@",outError);
                        }
                    });
                }
                if(outSelector == 4)
                    outSelector = 1;
                break;
            case 87:
                recordMovie = false;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Play movie, time %lli",[mMovie duration].timeValue);
                    [mMovie gotoBeginning];
                    [mMovie play];
                });
                outSelector = 4;
                break;
                
            default:
                return incomingEvent;

                break;
        }
                return (NSEvent*)nil;
    }];
    
    
    mavController = [[MavController alloc] init];
    
}

//
//----------------
//


-(void)setup{
    glewInit();
    
    //
    //Init filters
    //
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
    
    chromaFilter = [[ChromaFilter alloc] init];
    
    //
    //Core Image Context
    //
    CGLContextObj  contextGl = CGLContextObj([[[[[globalController viewManager] glViews] objectAtIndex:0] openGLContext] CGLContextObj]);
    CGLPixelFormatObj pixelformatGl = CGLGetPixelFormat(contextGl);
    NSDictionary * options = @{kCIContextWorkingColorSpace:(id)kCFNull};
    ciContextMain = [CIContext contextWithCGLContext:contextGl
                                         pixelFormat:pixelformatGl
                                          colorSpace:nil
                                             options:options];
    
    
    
    //
    //Prepare movie recording
    //
    
    QTOpenGLTextureContextCreate(kCFAllocatorDefault,
                                 contextGl,
                                 pixelformatGl,
                                 nil,
                                 &movieTextureContext);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError * error;
        mMovie = [[QTMovie alloc] initToWritableData:[NSMutableData data] error:&error];
        if (!mMovie) {
            [[NSAlert alertWithError:error] runModal];
        }
        
        [mMovie setVisualContext:movieTextureContext];
    });
    
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if(object == Prop(@"chromaMin") || object == Prop(@"chromaMax")){
        [chromaFilter setMinHueAngle:PropF(@"chromaMin") maxHueAngle:PropF(@"chromaMax")];
    }
}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
    [mavController update];
    
    //Set camera active flag
    for(int i=0;i<3;i++){
        DecklinkCallback * callback = [blackMagicController callbacks:i];
        if(outSelector == i +1){
            callback->cameraActive = true;
        } else {
            callback->cameraActive = false;
        }
    }
    
    
    //Update frames from camera
    for(int i=0;i<3;i++){
        DecklinkCallback * callback = [blackMagicController callbacks:i];
        if(callback->newFrame){
            pthread_mutex_lock(&callback->mutex);
            callback->newFrame = false;
            
            int w = callback->w;
            int h = callback->h;
            NSSize size = NSMakeSize(w, h);
            unsigned char * bytes = callback->bytes;
            
            //Update ofImage
            currentFrames[i].setFromPixels(bytes, w, h, OF_IMAGE_COLOR);
            
            //Update record image if recording
            if(recordMovie && outSelector - 1 == i){
                NSBitmapImageRep * imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&bytes
                                                                                      pixelsWide:w pixelsHigh:h
                                                                                   bitsPerSample:8 samplesPerPixel:3
                                                                                        hasAlpha:NO isPlanar:NO
                                                                                  colorSpaceName:NSDeviceRGBColorSpace
                                                                                    bitmapFormat:0
                                                                                     bytesPerRow:3*w bitsPerPixel:8*3];
                
                recordImage = [[NSImage alloc] initWithSize:size];
                [recordImage addRepresentation:imageRep];
                /*{
                 NSData *imageData = [recordImage TIFFRepresentation];
                 NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
                 NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
                 imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
                 [imageData writeToFile:@"/Users/jonas/Desktop/test.jpg" atomically:NO];
                 }*/
            }
            pthread_mutex_unlock(&callback->mutex);
            
            //Set Core Image
            uint textureId = currentFrames[i].getTextureReference().getTextureData().textureID;
            currentCIImage[i] = [self createCIImageFromTexture:textureId size:size];
            currentCIImage[i] = [self filterCIImage:currentCIImage[i]];
        }
    }
    
    
    //Record movie
    if(recordMovie){
        if(outSelector != 4){
            int timeDiff = ofGetElapsedTimeMillis() - millisAtLastFrameRecord;
            dispatch_async(dispatch_get_main_queue(), ^{
                [mMovie addImage:recordImage forDuration:QTMakeTime(timeDiff, 1000) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys: @"jpeg", QTAddImageCodecType, nil]];
                [mMovie setCurrentTime:[mMovie duration]];
                
                millisAtLastFrameRecord = ofGetElapsedTimeMillis();
            });
        }
    }
    
    
    
    // check for new frame from movie
    if(outSelector == 4){
        const CVTimeStamp * outputTime;
        [[drawingInformation objectForKey:@"outputTime"] getValue:&outputTime];
        QTVisualContextTask(movieTextureContext);
        if (movieTextureContext != NULL && QTVisualContextIsNewImageAvailable(movieTextureContext, outputTime)) {
            // if we have a previous frame release it
            if (NULL != movieCurrentFrame) {
                CVOpenGLTextureRelease(movieCurrentFrame);
                movieCurrentFrame = NULL;
            }
            // get a "frame" (image buffer) from the Visual Context, indexed by the provided time
            OSStatus status = QTVisualContextCopyImageForTime(movieTextureContext, NULL, outputTime, &movieCurrentFrame);
            
            // the above call may produce a null frame so check for this first
            // if we have a frame, then draw it
            if ( ( status != noErr ) && ( movieCurrentFrame != NULL ) ){
                NSLog(@"Error: OSStatus: %ld",status);
                CFRelease( movieCurrentFrame );
                
                movieCurrentFrame = NULL;
            }
        } else if  (movieTextureContext == NULL){
            NSLog(@"No textureContext");
            if (NULL != movieCurrentFrame) {
                CVOpenGLTextureRelease(movieCurrentFrame);
                movieCurrentFrame = NULL;
            }
        }
    }
    
}

//
//----------------
//

-(CIImage*) imageForSelector:(int)selector{
    if(selector == 0){
        return nil;
    }
    if(selector > 0 && selector <= 3){
        return currentCIImage[selector-1];
    }
    if(selector == 4){
    }
}

//
//----------------
//


-(CIImage*) createCIImageFromTexture:(GLint)tex size:(NSSize)size{
    CIImage * image = [CIImage imageWithTexture:tex size:CGSizeMake(size.width, size.height) flipped:NO colorSpace:nil];
    return image;
}


//
//----------------
//


-(CIImage*) filterCIImage:(CIImage*)inputImage{
    CIImage * _outputImage = inputImage;
    
    if(PropB(@"deinterlace")){
        [deinterlaceFilter setInputImage:_outputImage];
        _outputImage = [deinterlaceFilter valueForKey:@"outputImage"];
    }
    
    if(PropB(@"chromaKey") && inputImage == [self imageForSelector:1]){
        [chromaFilter setInputImage:_outputImage];
        [chromaFilter setBackgroundImage:[self imageForSelector:2]];
        _outputImage = [chromaFilter outputImage];
    }
    
    /* [blurFilter setValue:[NSNumber numberWithFloat:PropF(@"blur")] forKey:@"inputRadius"];
     [blurFilter setValue:_outputImage forKey:@"inputImage"];
     _outputImage = [blurFilter valueForKey:@"outputImage"];*/
    
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
    else if(outSelector > 0 && outSelector <= 3){
        /*        if(outSelector == 2){
         glScaled(1.333,1,1);
         }
         */
        
        CIImage * outImage = [self imageForSelector:outSelector];
        
        glScaled(1.0/[outImage extent].size.width, 1.0/[outImage extent].size.height, 1);
        [ciContext drawImage:outImage inRect:[outImage extent] fromRect:[outImage extent]];
    }
    else if(outSelector == 4){
        if(movieCurrentFrame != nil ){
            //Draw video
            GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
            
            GLenum target = CVOpenGLTextureGetTarget(movieCurrentFrame);
            GLint _name = CVOpenGLTextureGetName(movieCurrentFrame);
            
            // get the texture coordinates for the part of the image that should be displayed
            CVOpenGLTextureGetCleanTexCoords(movieCurrentFrame, bottomLeft, bottomRight, topRight, topLeft);
            
            glEnable(target);
            glBindTexture(target, _name);
            ofSetColor(255,255, 255, 255);
            glPushMatrix();
            
            glBegin(GL_QUADS);{
                glTexCoord2f(topLeft[0], topLeft[1]);  glVertex2f(0, 0);
                glTexCoord2f(topRight[0], topRight[1]);     glVertex2f(1,0);
                glTexCoord2f(bottomRight[0], bottomRight[1]);    glVertex2f(1,  1);
                glTexCoord2f(bottomLeft[0], bottomLeft[1]); glVertex2f( 0, 1);
            }glEnd();
            
            glPopMatrix();
            
            
            glDisable(target);
            
            QTVisualContextTask(movieTextureContext);
        }
    }
}


-(void)draw:(NSDictionary *)drawingInformation{
    ciContext = ciContextMain;

    [self render];
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{
    ofBackground(255, 255, 255);
    ofSetColor(255, 255, 255);
    
    float w = ofGetWidth();
    
    float mW = w/3.0;
    float mH = mW * 3.0/4.0;
    
    for(int i=0;i<3;i++){
        ofFill();
        ofSetColor(255, 255, 255);
        currentFrames[i].draw(i*mW,0,mW,mH);
        
        if(i == outSelector - 1){
            ofNoFill();
            glLineWidth(5.0);
            ofSetColor(255, 0, 0);
            ofRect(i*mW+3,3,mW-6,mH-6);
            glLineWidth(1.0);
        }
    }
    
    ofTranslate(0,mH+30);
    //  ofScale(mW*3,mH*3);
    //   [self render];
    // [ciContext drawImage:renderImage inRect:[renderImage extent] fromRect:[renderImage extent]];
    
    
}

-(void)controlKeyPressed:(int)key modifier:(int)modifier{
    //    NSLog(@"%i",key);
   
}
@end
