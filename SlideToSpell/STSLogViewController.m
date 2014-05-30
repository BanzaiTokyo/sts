//
//  STSLogViewController.m
//  SlideToSpell
//
//  Created by Toxa on 30/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "STSLogViewController.h"
#import "STSGameLogic.h"

@interface STSLogViewController ()

@end

@implementation STSLogViewController

-(void)viewDidLoad {
    highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"];
}

-(void)viewWillAppear:(BOOL)animated {
    _labelScore.text = [NSString stringWithFormat:@"%d", score];
    _labelHighScore.text = [NSString stringWithFormat:@"%d", highScore];
    _switchZenMode.on = zenMode;
    [_tableView reloadData];
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return wordsLog.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = wordsLog[indexPath.row];
    return cell;
}

- (IBAction)toggleZenMode:(id)sender {
    zenMode = _switchZenMode.on;
}
@end
