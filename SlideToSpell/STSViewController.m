//
//  STSViewController.m
//  SlideToSpell
//
//  Created by Toxa on 22/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "AudioToolbox/AudioToolbox.h"
#import "STSViewController.h"
#import "STSGameLogic.h"

#define NORMALCOLOR [UIColor whiteColor]
#define HIGHLIGHTCOLOR [UIColor redColor]
#define FLASHTIME 0.3
#define FLASHSCALEFACTOR 2
#define FALLTIME 0.6

CGSize screenSize, cellSize;

@class STSGridView;
@class STSViewController;
STSGridView *gridView;

int touchedRow, touchedCol;
BOOL scrollingHorizontal, fallSeveralColumns;

@interface STSScrollView : UIView {
    UILabel *labels[NUMROWS];
    int numItems;
}
-(void)scrollContentBy:(int)delta;
-(void)saveDataToGrid;
@end

@interface STSViewController () {
    BOOL isScrolling;
    STSScrollView *scroller;
    UITapGestureRecognizer *tapGesture;
}
-(void)checkAfterPush;
@end

@interface STSGridView : UIView {
    UILabel *labels[GRIDSIZE];
    STSViewController *parent;
}
@end
@implementation STSGridView
-(instancetype)initWithFrame:(CGRect)frame andParent:(STSViewController *)vc {
    self = [super initWithFrame:frame];
    parent = vc;
    for (int i=0; i<GRIDSIZE; i++)
        [self createLabelAtIndex:i];
    return self;
}

-(void)createLabelAtIndex:(int)idx {
    int x = idx / NUMROWS, y = idx % NUMROWS;
    CGRect r = CGRectMake(x*cellSize.width, y*cellSize.height, cellSize.width, cellSize.height);
    r = CGRectInset(r, 1, 1);
    labels[idx] = [[UILabel alloc] initWithFrame:r];
    labels[idx].textAlignment = NSTextAlignmentCenter;
    labels[idx].font = [UIFont fontWithName:@"Helvetica Neue" size:cellSize.height];
    [self addSubview:labels[idx]];
}

-(void)setLetterAtIndex:(int)idx {
    if (grid[idx].highlighted)
        labels[idx].backgroundColor = HIGHLIGHTCOLOR;
    else
        labels[idx].backgroundColor = NORMALCOLOR;
    labels[idx].text = [NSString stringWithFormat:@"%c", grid[idx].letter];
}

-(void)flashCascade:(NSArray *)cascade {
    [UIView animateWithDuration:FLASHTIME animations:^{
        for (NSNumber *n in cascade) {
            [labels[[n intValue]] setTransform:CGAffineTransformMakeScale(FLASHSCALEFACTOR, FLASHSCALEFACTOR)];
            labels[[n intValue]].alpha = 0;
        }
    }
    completion:^(BOOL finished) {
        if (finished) {
            int minX = NUMCOLS, maxX = 0;
            for (NSNumber *n in cascade) {
                int i = [n intValue];
                minX = MIN(i, minX);
                maxX = MAX(i, maxX);
                [labels[i] removeFromSuperview];
                labels[i] = nil;
            }
            fallSeveralColumns = minX != maxX;
            [self fallDown];
        }
    }];
}

-(void)fallDown {
    int i, t, k, x, iMaxDelay, numFallen;
    float fallDelays[NUMCOLS], maxDelay, actdelay;
    BOOL soundThisColumn;
    
    maxDelay = 0;
    for (i=0; i<NUMCOLS; i++) {
        fallDelays[i] = (arc4random() % 10)*0.01;
        if (fallDelays[i] > maxDelay)
            maxDelay = fallDelays[i];
    }
    maxDelay = 0;  iMaxDelay = 0;
    for (i=0; i<NUMCOLS; i++) {
        x = i*NUMROWS;
        t = NUMROWS - 1;
        while ((t >= 0) && (grid[x + t].letter > 0)) t--;
        k = t;  numFallen = 0;
        soundThisColumn = NO;
        while (k >= 0) { //fall visible letters
            if (grid[x + k].letter > 0) {
                grid[x + t].letter = grid[x + k].letter;
                grid[x + k].letter = 0;
                actdelay = fallDelays[i] + numFallen*0.1;
                if (actdelay > maxDelay) maxDelay = actdelay;
                if (t-k > iMaxDelay) iMaxDelay = t-k;
                CGPoint fallTo = CGPointMake(labels[x+k].center.x, (t+0.5)*cellSize.height);
                CGFloat fallDuration = FALLTIME*(t-k)/(NUMROWS-1);
                if (grid[x+t].letter && (!fallSeveralColumns || (fallSeveralColumns && !soundThisColumn))) {
                    soundThisColumn = YES;
                    [UIView animateWithDuration:fallDuration delay:actdelay options:UIViewAnimationOptionCurveEaseIn animations:^{
                        labels[x+k].center = fallTo;
                    } completion:^(BOOL finished) {
                        if (finished) {
                            SystemSoundID *sound1;
                            NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"BW_TileFall" withExtension:@"wav"];
                            AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, sound1);
                            AudioServicesPlaySystemSound(*sound1);
                        }
                    }];
                }
                else {
                    [UIView animateWithDuration:fallDuration delay:actdelay options:UIViewAnimationOptionCurveEaseIn animations:^{
                        labels[x+k].center = fallTo;
                    } completion:nil];
                }
                labels[x + t] = labels[x + k];
                t--;  numFallen++;
            }
            else if (labels[x+k])
                [labels[x+k] removeFromSuperview];
            labels[x+k] = nil;
            k--;
        }
        k = t+1;
        while (t >= 0) { //fall new letters to the top
            grid[x + t].letter = [GameLogic getNextLetter];
            grid[x + t].highlighted = NO;
            [self createLabelAtIndex:x+t];
            [self setLetterAtIndex:x+t];
            labels[x+t].center = CGPointMake(labels[x+t].center.x, (t-k+0.5)*cellSize.height);
            actdelay = fallDelays[i] + numFallen*0.1;
            if (actdelay > maxDelay) maxDelay = actdelay;
            CGPoint fallTo = CGPointMake(labels[x+t].center.x, (t+0.5)*cellSize.height);
            CGFloat fallDuration = FALLTIME*k/(NUMROWS-1);
            if (grid[x+t].letter && (!fallSeveralColumns || (fallSeveralColumns && !soundThisColumn))) {
                soundThisColumn = YES;
                [UIView animateWithDuration:fallDuration delay:actdelay options:UIViewAnimationOptionCurveEaseIn animations:^{
                    labels[x+t].center = fallTo;
                } completion:^(BOOL finished) {
                    if (finished) {
                        SystemSoundID *sound1;
                        NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"BW_TileFall" withExtension:@"wav"];
                        AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, sound1);
                        AudioServicesPlaySystemSound(*sound1);
                    }
                }];
            }
            else {
                [UIView animateWithDuration:fallDuration delay:actdelay options:UIViewAnimationOptionCurveEaseIn animations:^{
                    labels[x+t].center = fallTo;
                } completion:nil];
            }
            t--;  numFallen++;
        }
    }
    [parent performSelector:@selector(checkAfterPush) withObject:nil afterDelay:maxDelay+FALLTIME*iMaxDelay/(NUMROWS-1)];
}

@end

@implementation STSScrollView
+(instancetype)createScroller {
    CGRect r = CGRectZero;
    int numItems;
    if (!scrollingHorizontal) {
        numItems = NUMROWS;
        r.origin = CGPointMake(touchedCol*cellSize.width, 0);
        r.size.width = cellSize.width;
        r.size.height = screenSize.height;
    }
    else {
        numItems = NUMCOLS;
        r.origin = CGPointMake(0, touchedRow*cellSize.height);
        r.size.width = screenSize.width;
        r.size.height = cellSize.height;
    }
    STSScrollView *result = [[STSScrollView alloc] initWithFrame:r];
    result->numItems = numItems;
    r.size = cellSize;
    for (int i=0; i<numItems; i++) {
        if (!scrollingHorizontal)
            r.origin = CGPointMake(0, i*cellSize.height);
        else
            r.origin = CGPointMake(i*cellSize.width, 0);
        
        result->labels[i] = [[UILabel alloc] initWithFrame:CGRectInset(r, 1, 1)];
        result->labels[i].textAlignment = NSTextAlignmentCenter;
        result->labels[i].font = [UIFont fontWithName:@"Helvetica Neue" size:cellSize.height];
        result->labels[i].backgroundColor = NORMALCOLOR;
        int t;
        if (!scrollingHorizontal)
            t = touchedCol*NUMROWS + i;
        else
            t = i*NUMROWS + touchedRow;
        result->labels[i].text = [NSString stringWithFormat:@"%c", grid[t].letter];
        [result addSubview:result->labels[i]];
    }
    
    result.layer.shadowColor = [UIColor blackColor].CGColor;
    result.layer.shadowOffset = CGSizeZero;
    result.layer.shadowOpacity = 0.7;
    result.layer.shadowRadius = 4;
    result.layer.masksToBounds = NO;
    if (!scrollingHorizontal)
        r = CGRectInset(result.bounds, -4, 0);
    else
        r = CGRectInset(result.bounds, 0, -4);
    result.layer.shadowPath = [[UIBezierPath bezierPathWithRect:r] CGPath];
    
    return result;
}

-(void)scrollContentBy:(int)delta {
    char temp[numItems];
    int i;
    
    if (delta < 0)
        delta = numItems - (-delta % numItems);
    for (i=0; i<numItems; i++)
        temp[(i+delta)%numItems] = [labels[i].text characterAtIndex:0];
    for (i=0; i<numItems; i++)
        labels[i].text = [NSString stringWithFormat:@"%c", temp[i]];
}

-(void)saveDataToGrid {
    for (int i=0; i<numItems; i++) {
        int t;
        if (!scrollingHorizontal)
            t = touchedCol*NUMROWS + i;
        else
            t = i*NUMROWS + touchedRow;
        grid[t].letter = [labels[i].text characterAtIndex:0];
        [gridView setLetterAtIndex:t];
    }
}
@end

@implementation STSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect r = [[UIScreen mainScreen] bounds];
    screenSize = r.size;
    cellSize.width = r.size.width / NUMCOLS;
    cellSize.height = r.size.height / NUMROWS;
    self.view.backgroundColor = [UIColor greenColor];
    gridView = [[STSGridView alloc] initWithFrame:r andParent:self];
    [self.view addSubview:gridView];
    [self initGame];
}

-(void)initGame {
    for (int i=0; i<GRIDSIZE; i++) {
        grid[i].highlighted = NO;
        grid[i].letter = [GameLogic getNextLetter];
        [gridView setLetterAtIndex:i];
    }
    isScrolling = NO;
    scroller = nil;
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapField:)];
    [gridView addGestureRecognizer:tapGesture];
    [self checkAfterPush];
}

CGPoint prevTouch;
int prevCol, prevRow;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:gridView];
    prevTouch = p;
    touchedCol = prevCol = p.x / cellSize.width;
    touchedRow = prevRow = p.y / cellSize.height;
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:gridView];
    int col = p.x / cellSize.width, row = p.y / cellSize.height;
    if (!isScrolling) {
        if (abs(p.x-prevTouch.x) > cellSize.width*0.2) {
            scrollingHorizontal = YES;
            isScrolling = YES;
        }
        else if (abs(p.y-prevTouch.y) > cellSize.height*0.2) {
            scrollingHorizontal = NO;
            isScrolling = YES;
        }
        if (isScrolling) {
            scroller = [STSScrollView createScroller];
            [self.view addSubview:scroller];
        }
    }
    else if (col != prevCol && scrollingHorizontal)
        [scroller scrollContentBy:col - prevCol];
    else if (row != prevRow && !scrollingHorizontal)
        [scroller scrollContentBy:row - prevRow];
    prevCol = col;  prevRow = row;
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (scroller) {
        [scroller saveDataToGrid];
        [scroller removeFromSuperview];
        scroller = nil;
        isScrolling = NO;
        [self checkAfterPush];
    }
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

-(void)tapField:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:gridView];
    int col = p.x / cellSize.width, row = p.y / cellSize.height, idx;
    idx = col*NUMROWS+row;
    if (grid[idx].highlighted) {
        int cascadeswithCell = 0;
        NSArray *cascade = nil;
        for (NSArray *set in Cascads)
            if ([set containsObject:@(idx)]) {
                cascade = set;
                cascadeswithCell++;
            }
        if (cascadeswithCell == 1)
            [self flashCascade:cascade];
        else
            ; //tapped letter belongs to several words, don't know which to remove
    }
}

-(void)checkAfterPush {
    [GameLogic findCascades];
    NSMutableSet *allFoundDice = [NSMutableSet setWithCapacity:Words.count*MINWORDLENGTH];
    for (NSArray *set in Cascads)
        [allFoundDice addObjectsFromArray:set];
    for (int i=0; i<GRIDSIZE; i++) {
        grid[i].highlighted = [allFoundDice containsObject:@(i)];
        [gridView setLetterAtIndex:i];
    }
}

-(void)flashCascade:(NSArray *)cascade {
    [gridView flashCascade:cascade];
    for (NSNumber *n in cascade) {
        grid[[n intValue]].letter = 0;
        grid[[n intValue]].highlighted = NO;
    }
}

@end
