//
//  DesuViewController.h
//  Desu
//
//  Created by Stefan Dasbach on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Modulater.h"
#import "Demodulater.h"

@interface DesuViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIButton *ListenButton;
@property (strong, nonatomic) IBOutlet UIButton *PlayButton;
@property (weak, nonatomic) IBOutlet UILabel *highLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratioLabel;

@property (strong, nonatomic) Modulater *modulator;
@property (strong, nonatomic) Demodulater *listener;
@end
