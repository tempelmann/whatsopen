//
//  Alerts.h
//  kExpcalc
//
//  Created by Franklin Marmon on 5/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Alerts : NSObject {

}

-(void) doInfoAlertWithTitle:(NSString *)text infoText:(NSString *)info forWindow:(NSWindow *)window withSelector:(SEL)sel withDelegate:(id)del runModal:(Boolean)modal;

@end
