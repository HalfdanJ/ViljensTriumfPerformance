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
        connected=  serial.setup("/dev/tty.usbserial-FT5CHURVA", 9600);
        
    }
    return self;
}

-(void) update {
    if(connected	){
        while(serial.available()){
            incommingBytes[incommingBytesIndex++] = serial.readByte();
            if(incommingBytes[incommingBytesIndex-1] == '\n'){
                incommingBytesIndex = 0;
                NSString * incommingStr = [NSString stringWithUTF8String:incommingBytes];
                NSLog(@"Got msg: %@",incommingStr);
                
                if([incommingStr rangeOfString:@"RECONFIG"].location != NSNotFound){
                    NSLog(@"Reconfig");
                    
                    serial.writeByte('v');
                    serial.writeByte('1');
                    serial.writeByte('%');
                }  else {
                    NSError *error = NULL;
                    NSRegularExpression *regex = [NSRegularExpression
                                                  regularExpressionWithPattern:@"OUT+%i+%i IN+%i+%i VID"
                                                  options:NSRegularExpressionCaseInsensitive
                                                  error:&error];
                    [regex enumerateMatchesInString:incommingStr options:0 range:NSMakeRange(0, [incommingStr length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                        // your code to handle matches here
                        NSLog(@"Match %@",match);
                    }];
                }
                
                memset(incommingBytes,0,sizeof(incommingBytes));
            }
        }
    }
}

@end
