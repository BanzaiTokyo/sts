//
//  STSSettingsViewController.m
//  SlideToSpell
//
//  Created by Toxa on 04/06/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "STSSettingsViewController.h"
#import "STSAppDelegate.h"
#import "STSGameLogic.h"

@implementation STSSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [STSAppDelegate setBanzaiFont:self.view];
    _difficultySegment.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"difficulty"];
}

- (IBAction)setDifficulty:(UISegmentedControl *)sender {
    difficulty = sender.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:difficulty forKey:@"difficulty"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
