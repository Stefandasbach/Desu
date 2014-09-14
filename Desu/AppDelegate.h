//
//  AppDelegate.h
//  Desu
//
//  Created by Bram Wasti on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Modulater.h"
#import "Demodulater.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) Modulater *modulator;
@property (strong, nonatomic) Demodulater *listener;


@end
