//
//  DeinterlaceFilter.h
//  ViljensTriumf
//
//  Created by Jonas Jongejan on 05/10/12.
//
//

#import <CoreImage/CoreImage.h>

@interface DeinterlaceFilter : CIFilter{
    CIImage   *inputImage;
}
@end
