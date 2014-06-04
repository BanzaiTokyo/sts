//
//  STSHelpViewController.m
//  SlideToSpell
//
//  Created by Toxa on 04/06/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "STSHelpViewController.h"
#import "STSAppDelegate.h"

@implementation STSHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [STSAppDelegate setBanzaiFont:self.view];
    [_helpText sizeToFit];
}

@end
