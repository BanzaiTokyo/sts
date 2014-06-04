//
//  STSHomeViewController.h
//  SlideToSpell
//
//  Created by Toxa on 03/06/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface STSHomeViewController : UIViewController<GKLocalPlayerListener, GKGameCenterControllerDelegate>
@property (strong, nonatomic) IBOutlet UIView *gridView;
@property (strong, nonatomic) IBOutlet UIButton *btnPlay;
@property (strong, nonatomic) IBOutlet UILabel *labelHighScore;

@end
