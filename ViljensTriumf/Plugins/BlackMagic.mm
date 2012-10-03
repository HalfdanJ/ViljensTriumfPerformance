#import "BlackMagic.h"
#import <ofxCocoaPlugins/Keystoner.h>


@implementation BlackMagic

-(void)initPlugin{
    [self addPropF:@"whiteBack"];
    [self addPropF:@"whiteFront"];
    [self addPropF:@"grovKalibrering"];
    
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
        if (deckLinkInputs[index]->EnableVideoInput(modeList[2]->GetDisplayMode(), bmdFormat8BitYUV, videoInputFlags) != S_OK)
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


-(void)update:(NSDictionary *)drawingInformation{
    for(int i=0;i<2;i++){
        if(callbacks[i]->newFrame){
            callbacks[i]->newFrame = false;
            int w = callbacks[i]->w;
            int h = callbacks[i]->h;
            
            if(currentFrames[i].width != w){
                currentFrames[i].allocate(w, h, OF_IMAGE_COLOR);
            }
            
            unsigned char * bytes = callbacks[i]->bytes;
            currentFrames[i].setFromPixels(bytes, w, h, OF_IMAGE_COLOR);
        }
    }
}


//
//----------------
//

-(void)draw:(NSDictionary *)drawingInformation{
    ofFill();
    
    ofSetColor(255,255,255);
    currentFrames[0].draw(0,0,1,1);
    //currentFrames[1].draw(0,0,0.5,1);
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{    
}

@end
