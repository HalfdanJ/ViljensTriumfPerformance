#include "Blackmagic.h"
#include <mach/mach_time.h>
#import <Quartz/Quartz.h>
@implementation SubtitleItem
@synthesize line1,line2;
@end


@implementation Blackmagic
@synthesize colorCorrectionFilter, gloomFilter, exposureFilter;

-(void) initPlugin{
	selectedCam = 0;
	fadeTo = -1;
	fade = -1;
	countdownInt = 0;
	
	titleImage = 0;
	titleFade = 0;
	
	subreceiver = new ofxOscReceiver();
	subreceiver->setup(12345);
	subtext1 = @"";
	subtext2 = @"";
	
	outputImage = nil;
	clockVisible = NO;
	/*
	 subtext = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"file://localhost/Users/friends/Friends/of_preRelease_v0061_osxSL_FAT/apps/jonas/FriendsMixer/Plugins/BlackMagic/subtitle.txt"]];
	 subarray = [NSMutableArray array];
	 
	 [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:200] named:@"SelectedSubtitle"];
	 blackSubtitle = NO;
	 
	 
	 NSArray * lines = [subtext componentsSeparatedByString:@"\n"];
	 NSLog(@"%@",lines);
	 
	 int i=0;
	 SubtitleItem * nItem = [[SubtitleItem alloc]init];
	 for(NSString * line in lines){
	 
	 
	 if([line length] > 0){
	 line = [NSString stringWithFormat:@" %@ ",line];
	 if(i ==0)
	 [nItem setLine1:line];
	 else if(i==1)
	 [nItem setLine2:line];
	 }
	 
	 
	 
	 i++;
	 if(i >= 3){
	 [subarray addObject:nItem];
	 i=0;
	 nItem = [[SubtitleItem alloc]init];
	 }
	 }*/
	
	[NSEvent addLocalMonitorForEventsMatchingMask:(NSKeyDownMask) handler:^(NSEvent *incomingEvent) {
        NSEvent *result = incomingEvent;
		NSLog(@"Events: %@",incomingEvent);
		
		if([incomingEvent keyCode] == 83){
			if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
				fadeTo = 0;
				fade = 0;
			} else {
				selectedCam = 0;
			}
		}
		if([incomingEvent keyCode] == 84){
			if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
				fadeTo = 1;
				fade = 0;
			} else {
				
				selectedCam = 1;
			}
		}
		if([incomingEvent keyCode] == 85){
			if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
				fadeTo = 2;
				fade = 0;
			} else {
				selectedCam = 2;
			}
		}
		
		
		//0
		if([incomingEvent keyCode] == 82){
			if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
				fadeTo = -2;
				fade = 0;
			} else {
				selectedCam = -2;
			}
		}
		
		
		//Top numbers
		if([incomingEvent keyCode] == 18){
			fadeTo = 10;
			fade = 0;
		}
		if([incomingEvent keyCode] == 19){
			fadeTo = 11;
			fade = 0;
		}
		if([incomingEvent keyCode] == 20){
			fadeTo = 12;
			fade = 0;
		}
		if([incomingEvent keyCode] == 21){
			fadeTo = 13;
			fade = 0;
		}
		if([incomingEvent keyCode] == 23){
			fadeTo = 14;
			fade = 0;
		}
		
		//T
		if([incomingEvent keyCode] == 17){
			titleImage = 1;
			titleFade = 0.01;
		}
		
		//o
		if([incomingEvent keyCode] == 31){
			outroImage = 1;
			outroFade = 0.01;
		}
		
		// space
		if([incomingEvent keyCode] == 49){
			if(titleImage != 0){
				if(titleFade > 0){
					titleImage++;
					titleFade = 0;
				} else {
					titleFade = 0.01;
				}
			}
			if(outroImage != 0){
				if(outroFade > 0){
					outroImage++;
					outroFade = 0;
				} else {
					outroFade = 0.01;
				}
			}
		}
		
		//z
		if([incomingEvent keyCode] == 6){
			[Prop(@"SelectedSubtitle") setIntValue:[Prop(@"SelectedSubtitle") intValue]-1];
			blackSubtitle = NO;
		}
		
		//x
		if([incomingEvent keyCode] == 7){
			[Prop(@"SelectedSubtitle") setIntValue:[Prop(@"SelectedSubtitle") intValue]+1];
			blackSubtitle = NO;
		}
		
		//s
		if([incomingEvent keyCode] == 1){
			blackSubtitle = !blackSubtitle;
		}
		
		//c
		if([incomingEvent keyCode] == 8){
			clockVisible = !clockVisible;
		}
		
		//enter 76
		if([incomingEvent keyCode] == 76){
			behindSceneOn = !behindSceneOn;
		}
		
		//v
		
		if([incomingEvent keyCode] == 9){
			countdownInt = 6;
			countdownStart = ofGetElapsedTimeMillis();
		}
		
		serial->writeByte( (selectedCam == 0 || fadeTo == 0) << 0   |   (selectedCam == 1 || fadeTo == 1) << 1 );
		
		
        return result;
    }];
	
	behindSceneOn = NO;
	
	colorCorrectionFilter = [[CIFilter filterWithName:@"CIColorControls"] retain];	    // Color filter
	[colorCorrectionFilter setDefaults];                                                // set the filter to its default values
	
	gloomFilter = [[CIFilter filterWithName:@"CIBloom"] retain];
	[gloomFilter setDefaults];
	
	exposureFilter = [[CIFilter filterWithName:@"CIExposureAdjust"] retain];
	[exposureFilter setDefaults];
	
	dissolveFilter = [[CIFilter filterWithName:@"CIDissolveTransition"] retain];
	[dissolveFilter setDefaults];
	
	atopFilter = [[CIFilter filterWithName:@"CISourceOverCompositing"] retain];
	[atopFilter setDefaults];
	
	
	
	[Chromakey class];
	
	chromaFilter = [[CIFilter filterWithName:@"Chroma"] retain];
	[chromaFilter setDefaults];
	[chromaFilter setValue:[NSNumber numberWithFloat:1.4] forKey:@"sensitivity"];
	
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0 maxValue:2] named:@"Saturation"];
	[colorCorrectionFilter bind:@"inputSaturation" toObject:properties withKeyPath:@"Saturation.value" options:nil];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:-1 maxValue:1] named:@"Brightness"];
	[colorCorrectionFilter bind:@"inputBrightness" toObject:properties withKeyPath:@"Brightness.value" options:nil];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0.25 maxValue:4] named:@"Contrast"];
	[colorCorrectionFilter bind:@"inputContrast" toObject:properties withKeyPath:@"Contrast.value" options:nil];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:100] named:@"GloomRadius"];
	[gloomFilter bind:@"inputRadius" toObject:properties withKeyPath:@"GloomRadius.value" options:nil];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1.0] named:@"GloomIntensity"];
	[gloomFilter bind:@"inputIntensity" toObject:properties withKeyPath:@"GloomIntensity.value" options:nil];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-10 maxValue:10.0] named:@"Exposure"];
	[exposureFilter bind:@"inputEV" toObject:properties withKeyPath:@"Exposure.value" options:nil];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:10] named:@"ChromaSensitivity"];
	[chromaFilter bind:@"sensitivity" toObject:properties withKeyPath:@"ChromaSensitivity.value" options:nil];
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"ChromaRed"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"ChromaGreen"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"ChromaBlue"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0] named:@"ChromaActive"];
	[self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0] named:@"PorcheOverlay"];
	
	photosUrl[0] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/B-roll/cropped/appartement.jpg"];
	photosUrl[1] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/B-roll/cropped/japanese-restaurant.jpg"];
	photosUrl[2] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/B-roll/cropped/gade.jpg"];
	photosUrl[3] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/B-roll/cropped/New%20York%20City_frihedsgudin%20copy.jpg"];
	photosUrl[4] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/B-roll/cropped/central%20Perk_r%C3%B8d.jpg"];
	
	
	titleUrl[0] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/title1.png"];
	titleUrl[1] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/title2.psd"];
	titleUrl[2] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/title3.psd"];
	titleUrl[3] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/title4.psd"];
	titleUrl[4] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/title5.psd"];
	titleUrl[5] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/title6.psd"];
	titleUrl[6] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/title7.psd"];
	
	outroUrl[0] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro1.psd"];
	outroUrl[1] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro2.psd"];
	outroUrl[2] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro3.psd"];
	outroUrl[3] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro4.psd"];
	outroUrl[4] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro5.psd"];
	outroUrl[5] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro6.psd"];
	outroUrl[6] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro7.psd"];
	outroUrl[7] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro8.psd"];
	outroUrl[8] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro9.psd"];
	outroUrl[9] = [NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/Video/Titles/outro10.psd"];
	
	for(int i=0;i<10;i++){
		if(titleUrl[i] != nil){
			titles[i] = [CIImage imageWithContentsOfURL:titleUrl[i]];
		}
	}
	
	
	for(int i=0;i<15;i++){
		if(outroUrl[i] != nil){
			outro[i] = [CIImage imageWithContentsOfURL:outroUrl[i]];
		}
	}
	
	
	for(int i=0;i<10;i++){
		if(photosUrl[i] != nil){
			ciPhotos[i] = [CIImage imageWithContentsOfURL:photosUrl[i]];
		}
	}
	behindScene  = [CIImage imageWithContentsOfURL:[NSURL URLWithString:@"file://localhost/Users/friends/Documents/behindthescene.psd"]];
	
	lawyer[0] = [CIImage imageWithContentsOfURL:[NSURL URLWithString:@"file://localhost/Users/friends/Desktop/Billeder/law_library.psd"]];
	lawyer[1] = [CIImage imageWithContentsOfURL:[NSURL URLWithString:@"file://localhost/Users/friends/Dropbox/Friends/B-roll/Ross%3F%20copy.jpg"]];
	
	porche = [CIImage imageWithContentsOfURL:[NSURL URLWithString:@"file://localhost/Users/friends/Desktop/Billeder/porsche.psd"]];
	
	NSDictionary *fontAttributesCountdown = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont labelFontOfSize:150.0f], NSFontAttributeName,
											 [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
											 nil];
	countdown = [[TimeCodeOverlay alloc] initWithAttributes:fontAttributesCountdown targetSize:NSMakeSize(720, 576 / 4.0)];	// text overlay will go in the bottom quarter of the display
	
	NSDictionary *fontAttributesCountdownMsg = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont labelFontOfSize:40], NSFontAttributeName,
												[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
												nil];
	countdownMsg = [[TimeCodeOverlay alloc] initWithAttributes:fontAttributesCountdownMsg targetSize:NSMakeSize(720, 576 / 4.0)];	// text overlay will go in the bottom quarter of the display
	
	
	serial = new ofSerial();
	serial->enumerateDevices();
	serialMatrix = new ofSerial();
	cout<<"Connecting to serial: "<<serial->setup("/dev/tty.usbserial-A600acvk", 115200)<<endl;
	cout<<"Connecting to serial for matrix: "<<serialMatrix->setup("/dev/tty.usbserial", 9600)<<endl;
	
	
}

-(void) awakeFromNib{
	[super awakeFromNib];
	
	[imageView1 setImage:[[NSImage alloc] initWithContentsOfURL:photosUrl[0]]];
	[imageView2 setImage:[[NSImage alloc] initWithContentsOfURL:photosUrl[1]]];
	[imageView3 setImage:[[NSImage alloc] initWithContentsOfURL:photosUrl[2]]];
	[imageView4 setImage:[[NSImage alloc] initWithContentsOfURL:photosUrl[3]]];
	[imageView5 setImage:[[NSImage alloc] initWithContentsOfURL:photosUrl[4]]];
	
	
	
}

-(void) setup{
	//	grabber[0] = [[QTKitVideoGrabber alloc] initWithWidth:720 height:576 device:5];
	//	grabber[1] = [[QTKitVideoGrabber alloc] initWithWidth:720 height:576 device:7];
	//	grabber[2] = [[QTKitVideoGrabber alloc] initWithWidth:720 height:576 device:2];
	//
	//	[(QTKitVideoGrabber*)grabber[0] listDevices];
    
	
	
	
	
	
	
	
	grabber[0] = new ofVideoGrabber();
	ofSetLogLevel(OF_LOG_NOTICE);
	grabber[0]->setVerbose(true);
	grabber[0]->listDevices();
	
	grabber[0]->setDeviceID(26);
	grabber[0]->initGrabber(720, 576, true);
	
	grabber[1] = new ofVideoGrabber();
	grabber[1]->setDeviceID(10);
	grabber[1]->initGrabber(720, 576, true);
	
	grabber[2] = new ofVideoGrabber();
	grabber[2]->setDeviceID(25);
	grabber[2]->initGrabber(720, 576, true);
	
	
	CGLContextObj  contextGl = CGLContextObj([[[[[globalController viewManager] outputViews] objectAtIndex:0] openGLContext] CGLContextObj]);		// the OpenGL context
	CGLPixelFormatObj pixelformatGl = CGLPixelFormatObj([[[[[globalController viewManager] outputViews] objectAtIndex:0] pixelFormat] CGLPixelFormatObj]); // pixelformat object that specifies buffer types and other attributes of the context
	
	ciContext = [[CIContext contextWithCGLContext:(CGLContextObj)contextGl
                                      pixelFormat:(CGLPixelFormatObj)pixelformatGl
										  options:[NSDictionary dictionaryWithObjectsAndKeys:
												   //  (id)displayColorSpace, kCIContextOutputColorSpace,
												   /*(id)displayColorSpace, kCIContextWorkingColorSpace,*/ nil]] retain];
	//	QCComposition * _QCComp = [QCComposition compositionWithFile:@"file://localhost/Users/friends/ChromaKey.qtzqc"] ;
	QCComposition * _QCComp = [QCComposition compositionWithFile:@"/Users/friends/Desktop/zoom.qtz"] ;
	qcRenderer = [[QCRenderer alloc] initWithCGLContext:contextGl pixelFormat:pixelformatGl colorSpace:CGColorSpaceCreateWithName (kCGColorSpaceGenericRGB) composition:_QCComp];
	
	
	
	NSDictionary *fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont labelFontOfSize:34.0f], NSFontAttributeName,
									[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
									[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.7], NSBackgroundColorAttributeName,
									nil];
	
	timeCodeOverlay = [[TimeCodeOverlay alloc] initWithAttributes:fontAttributes targetSize:NSMakeSize(720, 576 / 4.0)];	// text overlay will go in the bottom quarter of the display
	timeCodeOverlay2 = [[TimeCodeOverlay alloc] initWithAttributes:fontAttributes targetSize:NSMakeSize(720, 576 / 4.0)];	// text overlay will go in the bottom quarter of the display
	
	NSDictionary *fontAttributesClock = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont labelFontOfSize:150.0f], NSFontAttributeName,
										 [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
										 nil];
	clock = [[TimeCodeOverlay alloc] initWithAttributes:fontAttributesClock targetSize:NSMakeSize(720, 576 / 4.0)];	// text overlay will go in the bottom quarter of the display
	countdown = [[TimeCodeOverlay alloc] initWithAttributes:fontAttributesClock targetSize:NSMakeSize(720, 576 / 4.0)];	// text overlay will go in the bottom quarter of the display
	
	
	NSDictionary *fontAttributesCountdownmsg = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont labelFontOfSize:100.0f], NSFontAttributeName,
												[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
												nil];
	
	
	countdownMsg = [[TimeCodeOverlay alloc] initWithAttributes:fontAttributesCountdownmsg targetSize:NSMakeSize(720, 576 / 4.0)];	// text overlay will go in the bottom quarter of the display
	
	
	ofEnableAlphaBlending();
	
	
	unsigned char bytes[5];
	bytes[0] = '1';
	bytes[1] = '*';
	bytes[2] = '3';
	bytes[3] = '!';
	bytes[4] = '\n';
	serialMatrix->flush(true, true);
	//	serialMatrix->writeBytes(bytes, 4);
	
	
	
}

-(CIImage*) imageForInput:(int)input{
	CIImage * img = nil;
	
	CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
	
	if(input >= 0 && input < 3){
		//		if(grabber[input]->isFrameNew()){
		img = [CIImage imageWithTexture:grabber[input]->getTextureReference().texData.textureID size:CGSizeMake(720, 576) flipped:YES colorSpace:cs];
		if(input == 1){
			//Chroma
			if(PropF(@"ChromaActive")){
				[chromaFilter setValue:img forKey:@"inputImage"];
				[chromaFilter setValue:lawyer[input] forKey:@"inputBackground"];
				
				NSColor * c = [chromaColor color];
				[chromaFilter setValue:[CIColor colorWithRed:PropF(@"ChromaRed") green:PropF(@"ChromaGreen") blue:PropF(@"ChromaBlue")] forKey:@"matchColor"];
				
				img = [chromaFilter valueForKey:@"outputImage"];
				
				//	[atopFilter  setValue:[chromaFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
				//	[atopFilter  setValue:lawyer[input] forKey:@"inputBackgroundImage"];
				//	img = [atopFilter valueForKey:@"outputImage"];
				
			}
		}
		//		}
	} else if(input == -2){
		img = [[CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]] imageByCroppingToRect:CGRectMake(0, 0, 720, 576)];
	} else if(input >= 10 && input <= 19){
		img = [ciPhotos[input-10] imageByCroppingToRect:CGRectMake(0, 0, 720, 576)];
	}
	
	return img;
	
}



-(void) update:(NSDictionary *)drawingInformation{
	//	for(int i=0;i<3;i++){
	//		[(QTKitVideoGrabber*)grabber[i] update];
	//	}
	
	
	while(serialMatrix->available()>0){
		cout<<"size "<<serialMatrix->available()<<endl;
		unsigned char * buf;
		serialMatrix->readBytes(buf, serialMatrix->available());
		cout<<(char*)buf<<endl;
		
		unsigned char bytes[5];
		bytes[0] = '1';
		bytes[1] = '*';
		bytes[2] = '3';
		bytes[3] = '!';
		bytes[4] = '\n';
		//	serialMatrix->writeBytes(bytes, 4);
	}
	
	while( subreceiver->hasWaitingMessages() )
	{
		// get the next message
		ofxOscMessage m;
		subreceiver->getNextMessage( &m );
		
		// check for mouse moved message
		if ( m.getAddress() == "/subtitle" )
		{
			// both the arguments are int32's
			string txt1 =  m.getArgAsString( 0 );
			string txt2 =  m.getArgAsString( 1 );
			
			if(strlen(txt1.c_str()) > 0){
				subtext1 = [NSString stringWithFormat:@" %s ", txt1.c_str()];
			} else {
				subtext1 = @"";
			}
			if(strlen(txt2.c_str()) > 0){
				subtext2 = [NSString stringWithFormat:@" %s ", txt2.c_str()];
			} else {
				subtext2 = @"";
			}
		}
	}
	
	if(titleImage != 0){
		if(titleFade < 1 && titleFade > 0)
			titleFade += 0.06*30.0/ofGetFrameRate();
	}
	if(outroImage != 0){
		if(outroFade < 1 && outroFade > 0)
			outroFade += 0.06*30.0/ofGetFrameRate();
	}
	
	if(fade != -1){
		fade += 0.03*30.0/ofGetFrameRate();
		if(fade > 1){
			selectedCam = fadeTo;
			fade = -1;
			fadeTo = -1;
			
			serial->writeByte( (selectedCam == 0 || fadeTo == 0) << 0   |   (selectedCam == 1 || fadeTo == 1) << 1 );
			
		}
	}
	for(int i=0;i<3;i++){
		grabber[i]->update();
	}
	
	
	CIImage	    *inputImage = [self imageForInput:selectedCam];
	CIImage	    *inputImageTarget;
	
	CIImage	    *filterImage;
	
	
	if(inputImage != nil){
		imageRect = [inputImage extent];
		
		if(fade == -1){
			filterImage = inputImage;
		} else {
			inputImageTarget =  [self imageForInput:fadeTo];
			
			[dissolveFilter setValue:inputImage forKey:@"inputImage"];
			[dissolveFilter setValue:inputImageTarget forKey:@"inputTargetImage"];
			[dissolveFilter setValue:[NSNumber numberWithFloat:fade] forKey:@"inputTime"];
			
			filterImage = [dissolveFilter valueForKey:@"outputImage"];
		}
		
		
		
		[exposureFilter setValue:filterImage forKey:@"inputImage"];
		[colorCorrectionFilter setValue:[exposureFilter valueForKey:@"outputImage"]  forKey:@"inputImage"];
		[gloomFilter setValue:[colorCorrectionFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
		
		
		outputImage = [gloomFilter valueForKey:@"outputImage"];
		
		if(titleFade > 0 && titleImage != 0){
			CIImage * titleImg = titles[titleImage-1];
			if(titleImg != nil){
				
				[dissolveFilter setValue:[CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]] forKey:@"inputImage"];
				[dissolveFilter setValue:titleImg forKey:@"inputTargetImage"];
				[dissolveFilter setValue:[NSNumber numberWithFloat:titleFade] forKey:@"inputTime"];
				
				[atopFilter  setValue:[dissolveFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
				[atopFilter  setValue:outputImage forKey:@"inputBackgroundImage"];
				
				outputImage = [atopFilter valueForKey:@"outputImage"];
			} else {
				titleImage = 0;
			}
			
		}
		
		if(outroFade > 0 && outroImage != 0){
			CIImage * titleImg = outro[outroImage-1];
			if(titleImg != nil){
				
				[dissolveFilter setValue:[CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]] forKey:@"inputImage"];
				[dissolveFilter setValue:titleImg forKey:@"inputTargetImage"];
				[dissolveFilter setValue:[NSNumber numberWithFloat:outroFade] forKey:@"inputTime"];
				
				[atopFilter  setValue:[dissolveFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
				[atopFilter  setValue:outputImage forKey:@"inputBackgroundImage"];
				
				outputImage = [atopFilter valueForKey:@"outputImage"];
			} else {
				outroImage = 0;
			}
			
		}
		
		if (behindSceneOn) {
			[atopFilter  setValue:behindScene forKey:@"inputImage"];
			[atopFilter  setValue:outputImage forKey:@"inputBackgroundImage"];
			outputImage = [atopFilter valueForKey:@"outputImage"];
		}
		
		if (PropF(@"PorcheOverlay") && selectedCam == 1 ) {
			[atopFilter  setValue:porche forKey:@"inputImage"];
			[atopFilter  setValue:outputImage forKey:@"inputBackgroundImage"];
			outputImage = [atopFilter valueForKey:@"outputImage"];
		}
	}
	
	
	
	
}

-(void) draw:(NSDictionary *)drawingInformation{
	
	if(countdownInt > 0){
		glPushMatrix();
		
		glTranslated(0, 1, 0);
		glScaled(1.0/702,- 1.0/576, 1);
		
		CIImage	    *clockimg;
		clockimg = [countdown getImageForString:[NSString stringWithFormat:@"%i",countdownInt]];
		
		[ciContext drawImage:clockimg
					 atPoint:CGPointMake(0,200) // use integer coordinates to avoid interpolation
					fromRect:imageRect];
		
		/*		CIImage	    *clockimgMsg;
		 clockimgMsg = [countdownMsg getImageForString:[sceneText stringValue]];
		 
		 [ciContext drawImage:clockimgMsg
		 atPoint:CGPointMake(0,050) // use integer coordinates to avoid interpolation
		 fromRect:imageRect];*/
		
		
		glPopMatrix();
	} else {
		
		if(outputImage != nil){
			glPushMatrix();
			
			glTranslated(0, 1, 0);
			glScaled(1.0/702,- 1.0/576, 1);
			
			[ciContext drawImage:outputImage
						 atPoint:CGPointMake(0,0) // use integer coordinates to avoid interpolation
						fromRect:imageRect];
			
			CIImage	    *timecodeImage;
			CIImage	    *timecodeImage2;
			//		if(int(PropF(@"SelectedSubtitle")) < [subarray count] && !blackSubtitle){
			
			if(!behindSceneOn){
				if([subtext2 isEqualToString:@""]){
					timecodeImage2 = [timeCodeOverlay2 getImageForString:subtext1];
					
					[ciContext drawImage:timecodeImage2
								 atPoint:CGPointMake(0,-35) // use integer coordinates to avoid interpolation
								fromRect:imageRect];
				} else {
					
					timecodeImage = [timeCodeOverlay getImageForString:subtext1];
					
					[ciContext drawImage:timecodeImage
								 atPoint:CGPointMake(0,10) // use integer coordinates to avoid interpolation
								fromRect:imageRect];
					
					timecodeImage2 = [timeCodeOverlay2 getImageForString:subtext2];
					
					[ciContext drawImage:timecodeImage2
								 atPoint:CGPointMake(0,-35) // use integer coordinates to avoid interpolation
								fromRect:imageRect];
				}
			}
			//}
			
			
			if(clockVisible){
				NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
				[outputFormatter setDateFormat:@"HH:mm:ss"];
				
				NSString *newDateString = [outputFormatter stringFromDate:[[NSDate alloc]init]];
				
				NSLog(@"newDateString %@", newDateString);
				
				CIImage	    *clockimg;
				clockimg = [clock getImageForString:newDateString];
				
				[ciContext drawImage:clockimg
							 atPoint:CGPointMake(0,200) // use integer coordinates to avoid interpolation
							fromRect:imageRect];
				
			}
			
			
			glPopMatrix();
			
			
			//[qcRenderer renderAtTime:0.0 arguments:nil];
			
			/*ofSetColor(0, 0, 0);
			 ofRect(0, 0.74, 0.26+0.25+0.01, 0.31);
			 ofSetColor(255, 255, 255);
			 grabber[0]->draw(0, 0.75, 0.25, 0.3);
			 grabber[1]->draw(0.26, 0.75, 0.25, 0.3);
			 */
		}
		
	}
	
}

-(void) controlDraw:(NSDictionary *)drawingInformation{
	/*ofSetColor(0, 0, 0);
	 ofRect(0, 0, 960, 240);	*/
	
	
	float w = 437;
	float h = w * 3.0/4;
	
	for(int i=0;i<3;i++){
		glPushMatrix();
		ofSetColor(255,255,255);
		if(i == 0){
			
		} else if(i == 1 || i== 2){
			glTranslated((w+10)*i,0,0);
			
		}
		grabber[i]->draw(0,0,w,h);
		
		ofSetColor(0, 0, 0);
		ofRect(0,0, w, 2);
		
		if(selectedCam == i){
			ofSetColor(255, 0, 0);
			ofNoFill();
			ofSetLineWidth(3);
			ofRect(0,0,w,h);
		}
		
		if(fadeTo == i){
			ofSetColor(255.0*fade, 255.0*(1-fade), 0);
			ofNoFill();
			ofSetLineWidth(3);
			ofRect(0,0,w,h);
		}
		
		ofFill();
		ofSetLineWidth(1);
		
		glPopMatrix();
		
		
	}
	
	ofSetColor(255.0*PropF(@"ChromaRed"), 255.0*PropF(@"ChromaGreen"), 255.0*PropF(@"ChromaBlue"));
	ofRect(0, 0, 15, 400);
	
	/*
	 for(int i=0;i<3;i++){
	 [(QTKitVideoGrabber*)grabber[i] texture]->draw(960*(i/3.0), 0, 320, 240);
	 }*/
	
	//for(int i=0;i<3;i++){
	//		//	if([self alpha:i] > 0){
	//		//		@synchronized(grabber[i]){
	//		CGRect	    imageRect;
	//		CIImage	    *inputImage;
	//
	//		if([grabber[i] cvFrame] != nil){
	//			inputImage = [CIImage imageWithCVImageBuffer:[grabber[i] cvFrame]];
	//
	//			imageRect = [inputImage extent];
	//
	//			//		[exposureFilter setValue:inputImage forKey:@"inputImage"];
	//			//		[colorCorrectionFilter setValue:[exposureFilter valueForKey:@"outputImage"]  forKey:@"inputImage"];
	//			//		[gloomFilter setValue:[colorCorrectionFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
	//
	//
	//			// render our resulting image into our context
	//			//		glTranslated(0, 1, 0);
	//			//	glScaled(1.0/702, -1.0/576, 1);
	//			//	ofSetColor(255.0, 255, 255.0, 255.0*[self alpha:i]);
	//			[ciContext drawImage:inputImage
	//						 atPoint:CGPointMake(0,0) // use integer coordinates to avoid interpolation
	//						fromRect:imageRect];
	//		}
	//		//		}
	//		//	}
	//	}
}


@end


@implementation MixerView
-(void) awakeFromNib{
	NSLog(@"UIAOSHDJOUI");
}
-(void) keyDown:(NSEvent *)theEvent{
	NSLog(@"Event: %@",theEvent);
}

@end