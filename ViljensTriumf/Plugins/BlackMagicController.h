//
//  BlackMagicController.h
//  ViljensTriumf
//
//  Created by Jonas Jongejan on 05/10/12.
//
//

#import <Foundation/Foundation.h>
#import "DeckLinkAPI.h"
#import "DecklinkCallback.h"

@interface BlackMagicController : NSObject{

//    DeckLinkController*				deckLinkController;
    std::vector<IDeckLink*>			deviceList;
    
    IDeckLinkInput  *  deckLinkInputs[3];
    DecklinkCallback * callbacks[3];

}

-(void) initDecklink;
-(DecklinkCallback*)callbacks:(int)num;


@end
