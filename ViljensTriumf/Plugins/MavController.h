//
//  MavController.h
//  ViljensTriumf
//
//  Created by Jonas on 10/9/12.
//
//

#import <ofxCocoaPlugins/Plugin.h>

@interface MavController : NSObject
{
    ofSerial serial;
    
    
    char incommingBytes[100];
    int incommingBytesIndex;
}

-(void) update;
@end
