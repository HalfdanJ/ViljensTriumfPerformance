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
    bool connected;
    
    char incommingBytes[100];
    int incommingBytesIndex;
    
    NSMutableArray * outputs;
}

-(void) update;
@end
