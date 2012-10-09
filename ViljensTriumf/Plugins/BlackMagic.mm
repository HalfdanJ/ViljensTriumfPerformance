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
    
    NSError * error;
    mMovie = [[QTMovie alloc] initToWritableData:[NSMutableData data] error:&error];
    if (!mMovie) {
        [[NSAlert alertWithError:error] runModal];
    }
    
    
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
    
    NSDictionary * options = @{kCIContextWorkingColorSpace:(id)kCFNull};
    ciContextMain = [CIContext contextWithCGLContext:contextGl pixelFormat:pixelformatGl  colorSpace:nil options:options];
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        QTOpenGLTextureContextCreate(kCFAllocatorDefault,
                                     CGLContextObj(CGLGetCurrentContext()),		// the OpenGL context
                                     CGLGetPixelFormat(CGLGetCurrentContext()),
                                     nil,
                                     &movieTextureContext);
        
        [mMovie setVisualContext:movieTextureContext];
    });
    
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
      /*  if(millisAtLastFramePlayback < ofGetElapsedTimeMillis() - 400){
            millisAtLastFramePlayback = ofGetElapsedTimeMillis();
            playbackIndex++;
            if(recordIndex <= playbackIndex){
                playbackIndex = recordIndex-1;
            }
        }
        return movie[playbackIndex];*/
        /*        __block NSData * tiffData;
         dispatch_sync(dispatch_get_main_queue(), ^{
         tiffData = [[mMovie currentFrameImage] TIFFRepresentation];
         });
         CIImage *ciImage = [CIImage imageWithData:tiffData];
         return ciImage;*/
    }
}

-(void)update:(NSDictionary *)drawingInformation{
    //Set camera active flag
    
    for(int i=0;i<3;i++){
        DecklinkCallback * callback = [blackMagicController callbacks:i];
        if(outSelector == i +1){
            callback->cameraActive = true;
        } else {
            callback->cameraActive = false;
        }
    }
    
    
    for(int i=0;i<3;i++){
        DecklinkCallback * callback = [blackMagicController callbacks:i];
        if(callback->newFrame){
            pthread_mutex_lock(&callback->mutex);
            callback->newFrame = false;
            int w = callback->w;
            int h = callback->h;
            
            
            
            unsigned char * bytes = callback->bytes;
            currentFrames[i].setFromPixels(bytes, w, h, OF_IMAGE_COLOR);
            
            if(recordMovie && outSelector - 1 == i){
                
                
                
                    NSData * data = [NSData dataWithBytes:bytes length:w*h*3];
                 
                 NSBitmapImageRep * imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&bytes pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:3*w bitsPerPixel:8*3];
                 
                 
                 //                = [NSBitmapImageRep imageRepWithData:data];
                 NSSize imageSize = NSMakeSize(CGImageGetWidth([imageRep CGImage]), CGImageGetHeight([imageRep CGImage]));
                 
                 recordImage = [[NSImage alloc] initWithSize:imageSize];
                 [recordImage addRepresentation:imageRep];
                 
                 
                
                
                
                
                  {
                 NSData *imageData = [recordImage TIFFRepresentation];
                 NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
                 NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
                 imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
                 [imageData writeToFile:@"/Users/jonas/Desktop/test.jpg" atomically:NO];
                 }
                
            }
            
            pthread_mutex_unlock(&callback->mutex);
            
            currentCIImage[i] = [self createCIImageFromTexture:currentFrames[i].getTextureReference().getTextureData().textureID size:NSMakeSize(currentFrames[i].getWidth(), currentFrames[i].getHeight())];
            
            currentCIImage[i] = [self filterCIImage:currentCIImage[i]];
            
            if(recordMovie && outSelector - 1 == i){
                //movie[recordIndex++] = currentCIImage[i];
                /*
                 
                 CIContext *context = [CIContext contextWithOptions:nil];
                 CGImageRef cgImage = [context createCGImage:currentCIImage[i] fromRect:currentCIImage[i].extent];
                 CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
                 CFDataRef data = CGDataProviderCopyData(provider);
                 
                 CGRect extent = [currentCIImage[i] extent];
                 //png.Load((UInt8*)CFDataGetBytePtr(data), extent.size.width, extent.size.height, true);
                 
                 
                 unsigned char * bytes = (unsigned char*)CFDataGetBytePtr(data);
                 
                 NSBitmapImageRep * imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&bytes pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:4*w bitsPerPixel:8*4];
                 
                 
                 //                = [NSBitmapImageRep imageRepWithData:data];
                 NSSize imageSize = NSMakeSize(CGImageGetWidth([imageRep CGImage]), CGImageGetHeight([imageRep CGImage]));
                 
                 recordImage = [[NSImage alloc] initWithSize:imageSize];
                 [recordImage addRepresentation:imageRep];
                 
                 
                 */
                /*CIImage * ciImage = currentCIImage[i];
                 NSImage *recordImage = [[[NSImage alloc] initWithSize:NSSizeFromCGSize([ciImage extent].size)] autorelease];
                 
                 CGContextRef contextRef = (CGContextRef)
                 [[NSGraphicsContext currentContext]
                 graphicsPort];
                 CIContext *ciContext =
                 [CIContext contextWithCGContext:contextRef
                 options:[NSDictionary dictionaryWithObject:
                 [NSNumber numberWithBool:YES]
                 forKey:kCIContextUseSoftwareRenderer]];
                 [ciContext drawImage:ciImage
                 atPoint:CGPointMake(0, 0) fromRect:[ciImage extent]];
                 [recordImage unlockFocus];
                 
                 
                 
                 {
                 NSData *imageData = [recordImage TIFFRepresentation];
                 NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
                 NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
                 imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
                 [imageData writeToFile:@"/Users/jonas/Desktop/test.jpg" atomically:NO];
                 }
                 //
                 //                CFRelease(data);
                 //                CFRelease(cgImage);*/
            }
            
        }
    }
    
    if(recordMovie){
     /*    if(millisAtLastFrameRecord < ofGetElapsedTimeMillis() - 40){
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
         }
        */
        //  dispatch_async(dispatch_get_main_queue(), ^{
        if(outSelector != 4){
            CIImage * ciImage = [self imageForSelector:outSelector];
            
            
            
            int timeDiff = ofGetElapsedTimeMillis() - millisAtLastFrameRecord;
            //  if (ciImage && recordImage) {
            /* ofImage img = currentFrames[outSelector-1];
             unsigned char * bytes = img.getPixels();
             
             printf("%i\n",bytes[1]);
             
             NSData * data = [NSData dataWithBytes:bytes length:img.width*img.height*3];
             
             NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:data];
             NSSize imageSize = NSMakeSize(CGImageGetWidth([imageRep CGImage]), CGImageGetHeight([imageRep CGImage]));
             
             NSImage * image = [[NSImage alloc] initWithSize:imageSize];
             [image addRepresentation:imageRep];
             */
            
            
            /* NSCIImageRep *imageRep;
             imageRep = [NSCIImageRep imageRepWithCIImage:ciImage];
             NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
             [image addRepresentation:imageRep];
             */
            /*    {
             NSData *imageData = [image TIFFRepresentation];
             NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
             NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
             imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
             [imageData writeToFile:@"/Users/jonas/Desktop/test.jpg" atomically:NO];
             }
             */
               dispatch_async(dispatch_get_main_queue(), ^{
             [mMovie addImage:recordImage forDuration:QTMakeTime(timeDiff, 1000) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys: @"jpeg", QTAddImageCodecType, nil]];
             [mMovie setCurrentTime:[mMovie duration]];
             
             });
             millisAtLastFrameRecord = ofGetElapsedTimeMillis();
             //}
        }
        
        // });
    }
    
    
    //    NSLog(@"%lli",[mMovie currentTime].timeValue);
    
    // check for new frame
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
     NSLog(@"Error: OSStatus: %d",status);
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


//
//----------------
//
-(CIImage*) createCIImageFromTexture:(GLint)tex size:(NSSize)size{
    // NSLog(@"Create CI Image");
    CIImage * image = [CIImage imageWithTexture:tex size:CGSizeMake(size.width, size.height) flipped:NO colorSpace:nil];
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


-(void) render{
    
    
    
    
    
    ofFill();
    ofSetColor(255, 255, 255);
    
    if(outSelector == 0){
        ofSetColor(0, 0, 0);
        ofRect(0, 0, 1, 1);
    }
    else
        if(outSelector > 0 && outSelector <= 3){
            //         renderImage = [self createCIImageFromTexture:[self imageForSelector:outSelector]->getTextureReference().getTextureData().textureID size:NSMakeSize([self imageForSelector:outSelector]->getWidth(), [self imageForSelector:outSelector]->getHeight())];
            //
            //        renderImage = [self filterCIImage:renderImage];
            //
            /*        if(outSelector == 2){
             glScaled(1.333,1,1);
             }
             
             */
            CIImage * renderImage = [self imageForSelector:outSelector];
            
            glScaled(1.0/[renderImage extent].size.width, 1.0/[renderImage extent].size.height, 1);
            [ciContext drawImage:renderImage inRect:[renderImage extent] fromRect:[renderImage extent]];
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
    //    bwShader->end();
    // deinterlace->end();
}


-(void)draw:(NSDictionary *)drawingInformation{
    ciContext = ciContextMain;
    
    //   shader->begin();
    [self render];
    
    
    //grabber[0]->draw(0,0,1,1);
    
    //   shader->end();
    
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{
    if(!ciContextControl){
        CGLContextObj  contextGl =  CGLGetCurrentContext();
        CGLPixelFormatObj pixelformatGl = CGLGetPixelFormat(contextGl);
        //	CGLPixelFormatObj pixelformatGl = CGLPixelFormatObj([[[[[globalController viewManager] glViews] objectAtIndex:0] pixelFormat] CGLPixelFormatObj]);
        ciContextControl = [CIContext contextWithCGLContext:contextGl pixelFormat:pixelformatGl  colorSpace:nil options:nil];
    }
    ciContext = ciContextControl;
    
    
    
    ofBackground(255, 255, 255);
    ofSetColor(255, 255, 255);
    
    float w = ofGetWidth();
    float h = ofGetHeight();
    
    float mW = w/3.0;
    float mH = mW * 3.0/4.0;
    
    for(int i=0;i<3;i++){
        currentFrames[i].draw(i*mW,0,mW,mH);
    }
    
    ofTranslate(0,mH+30);
    //  ofScale(mW*3,mH*3);
    //   [self render];
    // [ciContext drawImage:renderImage inRect:[renderImage extent] fromRect:[renderImage extent]];
    
    
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
            recordIndex = 0;
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
            playbackIndex = 0;
            break;
            
        default:
            break;
    }
}
@end
