//
//  CoreImageViewer.h
//  ViljensTriumf
//
//  Created by Jonas on 10/9/12.
//
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface CoreImageViewer : NSView{
    CIImage * ciImage;
    CIContext *ciContext;
}
@property (readwrite, assign) CIImage * ciImage;
@end
