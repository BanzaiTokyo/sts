//
//  STSLogViewController.h
//  SlideToSpell
//
//  Created by Toxa on 30/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STSLogViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *labelScore;
@property (strong, nonatomic) IBOutlet UILabel *labelHighScore;
@property (strong, nonatomic) IBOutlet UISwitch *switchZenMode;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
