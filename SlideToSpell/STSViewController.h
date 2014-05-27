//
//  STSViewController.h
//  SlideToSpell
//
//  Created by Toxa on 22/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STSGameLogic.h"

@class STSViewController;

@interface STSScrollView : UIView {
    UILabel *labels[NUMROWS*3];
    int numItems;
}
-(void)saveDataScrolledBy:(int)delta;
@end

@interface STSGridView : UIView {
    UILabel *labels[GRIDSIZE];
}
@property (weak, nonatomic) STSViewController *parent;
-(void)halfHighlight:(int)idx;
@end

@interface STSViewController : UIViewController
@property (nonatomic) NSInteger score;
@property (strong, nonatomic) IBOutlet UILabel *lastWord;
@property (strong, nonatomic) IBOutlet UILabel *labelWordToFind;
@property (strong, nonatomic) IBOutlet UILabel *labelScore;
@property (strong, nonatomic) IBOutlet STSGridView *gridView;

@end

