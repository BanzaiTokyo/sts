//
//  STSHomeViewController.m
//  SlideToSpell
//
//  Created by Toxa on 03/06/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "STSHomeViewController.h"
#import "STSGameLogic.h"

@implementation STSHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [GameLogic getNextLetter];
    CGSize cellSize;
    cellSize.width = _gridView.frame.size.width / NUMCOLS;
    cellSize.height = _gridView.frame.size.height / NUMROWS;
    int pos[12] = {2, NUMROWS+2, NUMROWS*2+2, NUMROWS*3+2, NUMROWS*4+2,
                    NUMROWS+3, NUMROWS*2+3,
                   4, NUMROWS+4, NUMROWS*2+4, NUMROWS*3+4, NUMROWS*4+4};
    char letters[12] = {'S', 'L', 'I', 'D', 'E',
                        'T', 'O',
                        'S', 'P', 'E', 'L', 'L'};
    NSMutableArray *labels = [NSMutableArray array];
    for (int idx=0; idx<GRIDSIZE; idx++) {
        int x = idx / NUMROWS, y = idx % NUMROWS;
        CGRect r = CGRectMake(x*cellSize.width, y*cellSize.height, cellSize.width, cellSize.height);
        r = CGRectInset(r, 1, 1);
        UILabel *label = [[UILabel alloc] initWithFrame:r];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"BanzaiWordsFont-Bold" size:cellSize.height];
        label.backgroundColor = [UIColor colorWithWhite:224/255.0 alpha:1.0];
        [_gridView addSubview:label];
        labels[idx] = label;
    }
    for (int i=0; i<sizeof(letters); i++)
        ((UILabel *)labels[pos[i]]).text = [NSString stringWithFormat:@"%c", letters[i]];
    ((UILabel *)labels[NUMROWS*2+7]).backgroundColor = [UIColor colorWithRed:126/255.0 green:147/255.0 blue:209/255.0 alpha:1.0];
    CGRect r = ((UILabel *)labels[NUMROWS+6]).frame;
    r.origin.x += _gridView.frame.origin.x;
    r.origin.y += _gridView.frame.origin.y;
    r.size.width = cellSize.width*3;
    r.size.height = cellSize.height*3;
    _btnPlay.frame = r;
}

- (void)viewWillAppear:(BOOL)animated {
    int highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"];
    _labelHighScore.text = [NSString stringWithFormat:@"%d", highScore];
}

- (IBAction)returnActionForSegue:(UIStoryboardSegue *)returnSegue {
}

- (IBAction)goGameCenter:(id)sender {
}

- (IBAction)goFeedback:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.banzaitokyo.com"]];
}

@end
