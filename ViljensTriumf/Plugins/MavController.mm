//
//  MavController.m
//  ViljensTriumf
//
//  Created by Jonas on 10/9/12.
//
//

#import "MavController.h"

@implementation MavController

- (id)init
{
    self = [super init];
    if (self) {
        serial.setup("/dev/tty.usbserial-FT5CHURVA", 9600);

    }
    return self;
}

-(void) update {
    while(serial.available()){
        incommingBytes[incommingBytesIndex++] = serial.readByte();
        if(incommingBytes[incommingBytesIndex-1] == '\n'){
            incommingBytesIndex = 0;
            NSLog(@"Got msg");
            int cmp = strcmp(incommingBytes, "RECONFIG");
            NSLog(@"%i",cmp);
            if(cmp > 0){
                NSLog(@"Reconfig");
                
                serial.writeByte('v');
                serial.writeByte('1');
                serial.writeByte('%');
            } else {
                NSLog(@"%s",incommingBytes);
            }
            
            memset(incommingBytes,0,sizeof(incommingBytes));
        }
    }
}

@end
