//
//  DesuViewController.m
//  Desu
//
//  Created by Stefan Dasbach on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import "DesuViewController.h"

@interface DesuViewController ()
- (IBAction)play:(id)sender;
- (IBAction)listen:(id)sender;

@end

@implementation DesuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)play:(id)sender {
    if (_listener) {
        [_listener pause];
        _listener = nil;
    }
    if (!_modulator) {
        _modulator = [Modulater new];
        [_modulator initializeAudio];
        [_modulator play];
    }
}

- (IBAction)listen:(id)sender {
    if (_modulator) {
        [_modulator pause];
        _modulator = nil;
        
    }
    if (!_listener) {
        _listener = [Demodulater new];
        [_listener setLabelHigh:_highLabel AndLow:_lowLabel];
        [_listener initializeListener];
        [_listener listen];
    }
    
}
@end
