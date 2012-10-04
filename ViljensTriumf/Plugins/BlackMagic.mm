#import "BlackMagic.h"
#import <ofxCocoaPlugins/Keystoner.h>

@implementation BlackMagic

-(void)initPlugin{
    [self addPropF:@"min"];
    [self addPropF:@"max"];
    [self addPropF:@"blur"];

    
    [self initDeckLink];
    NSArray * deviceNames = [self getDeviceNameList];
	for (int deviceIndex = 0; deviceIndex < [deviceNames count]; deviceIndex++)
	{
		// Add this DeckLink device to the device list
        //		[deviceListPopup addItemWithTitle:[deviceNames objectAtIndex:deviceIndex]];
        NSLog(@"Device: %@",[deviceNames objectAtIndex:deviceIndex]);
	}
    
    
    
}

-(void) initDeckLink {
    IDeckLinkIterator*	deckLinkIterator = NULL;
	IDeckLink*			deckLink = NULL;
    IDeckLinkDisplayModeIterator*	displayModeIterator = NULL;
    
    IDeckLinkDisplayMode*			displayMode = NULL;
	bool				result = false;
    std::vector<IDeckLinkDisplayMode*>	modeList;
    
    callbacks[0] = new DecklinkCallback();
    callbacks[1] = new DecklinkCallback();
    callbacks[2] = new DecklinkCallback();
	
	// Create an iterator
	deckLinkIterator = CreateDeckLinkIteratorInstance();
	
	
	// List all DeckLink devices
	while (deckLinkIterator->Next(&deckLink) == S_OK)
	{
		// Add device to the device list
		deviceList.push_back(deckLink);
        
        
	}
	
    for(int index=0;index<deviceList.size();index++){
        // Get the IDeckLinkInput for the selected device
        if ((deviceList[index]->QueryInterface(IID_IDeckLinkInput, (void**)&deckLinkInputs[index]) != S_OK))
        {
            NSLog(@"This application was unable to obtain IDeckLinkInput for the selected device.");
        }
        
        
        
        //
        // Retrieve and cache mode list
        if (deckLinkInputs[index]->GetDisplayModeIterator(&displayModeIterator) == S_OK)
        {
            CFStringRef			modeName;
            int i=0;
            
            while (displayModeIterator->Next(&displayMode) == S_OK){
                modeList.push_back(displayMode);
                
                if (displayMode->GetName(&modeName) == S_OK)
                {
                    NSLog(@"Mode: %i %@",i++,(NSString *)modeName);
                }
            }
            
            displayModeIterator->Release();
        }
        
        
        
        
        // Set capture callback
        BMDVideoInputFlags		videoInputFlags = bmdVideoInputFlagDefault;
        
        deckLinkInputs[index]->SetCallback(callbacks[index]);
        
        // Set the video input mode
        int i = 2;
        if(index == 2){
            i = 11;
        }
        if (deckLinkInputs[index]->EnableVideoInput(modeList[i]->GetDisplayMode(), bmdFormat8BitYUV, videoInputFlags) != S_OK)
        {
            /*  [uiDelegate showErrorMessage:@"This application was unable to select the chosen video mode. Perhaps, the selected device is currently in-use." title:@"Error starting the capture"];
             return false;*/
            NSLog(@"This application was unable to select the chosen video mode. Perhaps, the selected device is currently in-use.");
        }
        
        // Start the capture
        if (deckLinkInputs[index]->StartStreams() != S_OK)
        {
            NSLog(@"This application was unable to start the capture. Perhaps, the selected device is currently in-use.");
            /*  [uiDelegate showErrorMessage:@"This application was unable to start the capture. Perhaps, the selected device is currently in-use." title:@"Error starting the capture"];
             return false;*/
        }
        
        
        
    }
    
	result = true;
	
    
}

//
//----------------
//


-(void)setup{
    glewInit();
    
    bwShader = new ofxShader();
    bwShader->setup("/Users/jonas/Development/ViljensTriumf/ViljensTriumf/Plugins/shaders/bwShader");

    deinterlace = new ofxShader();
    deinterlace->setup("/Users/jonas/Development/ViljensTriumf/ViljensTriumf/Plugins/shaders/deinterlace");

    for(int i=0;i<MOVIE_LENGTH;i++){
        
    }
    

    
    blurFilter = [[CIFilter filterWithName:@"CIGaussianBlur"] retain];
    [blurFilter setDefaults];
    
    NSBundle    *bundle = [NSBundle bundleForClass: [self class]];// 2
    NSString    *code = [NSString stringWithContentsOfFile: [bundle// 3
                                                             pathForResource: @"deinterlaceFilter"
                                                             ofType: @"cikernel"]];
    NSArray     *kernels = [CIKernel kernelsWithString: code];// 4
    hazeRemovalKernel = [kernels objectAtIndex:0];
    
    deinterlaceFilter = [CIFilter fil]
    
    
    CGLContextObj  contextGl = CGLContextObj([[[[[globalController viewManager] glViews] objectAtIndex:0] openGLContext] CGLContextObj]);
	CGLPixelFormatObj pixelformatGl = CGLPixelFormatObj([[[[[globalController viewManager] glViews] objectAtIndex:0] pixelFormat] CGLPixelFormatObj]);
    ciContextMain = [CIContext contextWithCGLContext:contextGl pixelFormat:pixelformatGl  colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];

}

//
//----------------
//

-(NSArray*)getDeviceNameList{
    NSMutableArray*		nameList = [NSMutableArray array];
	int					deviceIndex = 0;
	
	while (deviceIndex < deviceList.size())
	{
		CFStringRef	cfStrName;
		
		// Get the name of this device
		if (deviceList[deviceIndex]->GetDisplayName(&cfStrName) == S_OK)
		{
			[nameList addObject:(NSString *)cfStrName];
			CFRelease(cfStrName);
		}
		else
		{
			[nameList addObject:@"DeckLink"];
		}
        
		deviceIndex++;
	}
	
	return nameList;
}






-(ofImage*) imageForSelector:(int)selector{
    if(selector == 0){
        return nil;
    }
    if(selector > 0 && selector <= 3){
        return &currentFrames[selector-1];
    }
    if(selector == 4){
        if(millisAtLastFramePlayback < ofGetElapsedTimeMillis() - 40){
            millisAtLastFramePlayback = ofGetElapsedTimeMillis();
            playbackIndex++;
            if(recordIndex <= playbackIndex){
                playbackIndex = recordIndex-1;
            }
        }
        return &movieRecording[playbackIndex];
    }
}

-(void)update:(NSDictionary *)drawingInformation{
    for(int i=0;i<3;i++){
        if(callbacks[i]->newFrame){
            pthread_mutex_lock(&callbacks[i]->mutex);
            callbacks[i]->newFrame = false;
            int w = callbacks[i]->w;
            int h = callbacks[i]->h;
            
         /*   if(currentFrames[i].width != w){
                currentFrames[i].allocate(w, h, OF_IMAGE_COLOR);
            }
           */ 
            unsigned char * bytes = callbacks[i]->bytes;
            currentFrames[i].setFromPixels(bytes, w, h, OF_IMAGE_COLOR);            pthread_mutex_unlock(&callbacks[i]->mutex);
        }
    }
    
    if(recordMovie){
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
    }
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
    [blurFilter setValue:[NSNumber numberWithFloat:PropF(@"blur")] forKey:@"inputRadius"];
    [blurFilter setValue:inputImage forKey:@"inputImage"];
    CIImage * _outputImage = [blurFilter valueForKey:@"outputImage"];
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
         CIImage * outputImage = [self createCIImageFromTexture:[self imageForSelector:outSelector]->getTextureReference().getTextureData().textureID size:NSMakeSize([self imageForSelector:outSelector]->getWidth(), [self imageForSelector:outSelector]->getHeight())];
        
        outputImage = [self filterCIImage:outputImage];
        glScaled(1.0/[outputImage extent].size.width, 1.0/[outputImage extent].size.height, 1);
        //glScaled(1.0/720, 10/576.0, 1);
        [ciContext drawImage:outputImage
                              atPoint:CGPointMake(0,0) // use integer coordinates to avoid interpolation
                             fromRect:[outputImage extent]];
        
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
