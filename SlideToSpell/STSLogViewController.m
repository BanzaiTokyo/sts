//
//  STSLogViewController.m
//  SlideToSpell
//
//  Created by Toxa on 30/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "STSLogViewController.h"
#import "STSGameLogic.h"
#import "STSAppDelegate.h"

@implementation STSLogViewController

-(void)viewDidLoad {
    highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"];
    [STSAppDelegate setBanzaiFont:self.view];
}

-(void)viewWillAppear:(BOOL)animated {
    _labelScore.text = [NSString stringWithFormat:@"YOUR SCORE: %d", score];
    _labelHighScore.text = [NSString stringWithFormat:@"%d", highScore];
    _switchZenMode.on = zenMode;
}

- (IBAction)toggleZenMode:(id)sender {
    zenMode = _switchZenMode.on;
}

- (IBAction)goToHome:(id)sender {
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}
@end
