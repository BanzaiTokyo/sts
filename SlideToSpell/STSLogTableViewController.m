//
//  STSLogTableViewController.m
//  SlideToSpell
//
//  Created by Toxa on 03/06/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "STSLogTableViewController.h"
#import "STSGameLogic.h"

@interface STSLogTableViewController ()

@end

@implementation STSLogTableViewController

-(void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return wordsLog.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSString *w = wordsLog[wordsLog.count - 1 - indexPath.row];
    UILabel *l1 = cell.contentView.subviews[0], *l2 = cell.contentView.subviews[1];
    
    l1.font = [UIFont fontWithName:@"BanzaiWordsFont-Bold" size:20];
    l2.font = l1.font;
    
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:w.length];
    for (int i=0; i<w.length; i++)
        [counts addObject:@(defLetterScore[[w characterAtIndex:i]-65])];
    l1.text = [counts componentsJoinedByString:@"+"];
    l1.text = [NSString stringWithFormat:@"(%@)", l1.text];
    if (counts.count > 3)
        l1.text = [NSString stringWithFormat:@"%@ x %d", l1.text, counts.count];
    l1.text = [NSString stringWithFormat:@"%@ %@", w, l1.text];
    int wordScore = [[counts valueForKeyPath: @"@sum.self"] intValue];
    if (w.length > 3) {
        wordScore *= w.length;
        l1.textColor = [UIColor colorWithRed:90/255.0 green:0 blue:0 alpha:1.0];
    }
    else
        l1.textColor = [UIColor blackColor];
    l2.textColor = l1.textColor;
    l2.text = [NSString stringWithFormat:@"= %d", wordScore];
    
    return cell;
}


@end
