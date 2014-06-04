//
//  STSViewController.h
//  SlideToSpell
//
//  Created by Toxa on 22/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STSGameLogic.h"

@class STSGameViewController;

@interface STSScrollView : UIView {
    UILabel *labels[NUMROWS*3];
    int numItems;
}
-(void)saveDataScrolledBy:(int)delta;
@end

@interface STSGridView : UIView {
    UILabel *labels[GRIDSIZE];
}
@property (weak, nonatomic) STSGameViewController *parent;
-(void)halfHighlight:(int)idx;
@end

@interface STSGameViewController : UIViewController<UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UILabel *lastWord;
@property (strong, nonatomic) IBOutlet UILabel *labelTime;
@property (strong, nonatomic) IBOutlet UILabel *labelScore;
@property (strong, nonatomic) IBOutlet UIButton *btnPause;
@property (strong, nonatomic) IBOutlet STSGridView *gridView;
@property (strong, nonatomic) IBOutlet UIView *pauseView;

@end

