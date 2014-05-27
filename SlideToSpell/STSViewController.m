//
//  STSViewController.m
//  SlideToSpell
//
//  Created by Toxa on 22/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "AudioToolbox/AudioToolbox.h"
#import "STSViewController.h"

#define NORMALCOLOR [UIColor whiteColor]
#define HIGHLIGHTCOLOR [UIColor redColor]
#define FLASHTIME 0.3
#define FLASHSCALEFACTOR 2
#define FALLTIME 0.6

CGSize screenSize, cellSize;

int touchedRow, touchedCol;
BOOL scrollingHorizontal, fallSeveralColumns;

@interface STSViewController () {
    BOOL isScrolling;
    STSScrollView *scroller;
    UITapGestureRecognizer *tapGesture;
}
-(void)checkAfterPush;
@end

@implementation STSGridView
-(void)createGrid {
    for (int i=0; i<GRIDSIZE; i++)
        [self createLabelAtIndex:i];
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

-(void)halfHighlight:(int)idx {
    labels[idx].backgroundColor = [UIColor blueColor];
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
    [_parent performSelector:@selector(checkAfterPush) withObject:nil afterDelay:maxDelay+FALLTIME*iMaxDelay/(NUMROWS-1)];
}

@end

@implementation STSScrollView
-(instancetype)initWithFrame:(CGRect)frame {
    CGRect r = CGRectZero;
    if (!scrollingHorizontal) {
        numItems = NUMROWS;
        r.origin = CGPointMake(touchedCol*cellSize.width, -frame.size.height);
        r.size.width = cellSize.width;
        r.size.height = frame.size.height*3;
    }
    else {
        numItems = NUMCOLS;
        r.origin = CGPointMake(-frame.size.width, touchedRow*cellSize.height);
        r.size.width = frame.size.width*3;
        r.size.height = cellSize.height;
    }
    self = [super initWithFrame:r];
    r.size = cellSize;
    for (int i=0; i<numItems*3; i++) {
        if (!scrollingHorizontal)
            r.origin = CGPointMake(0, i*cellSize.height);
        else
            r.origin = CGPointMake(i*cellSize.width, 0);
        
        labels[i] = [[UILabel alloc] initWithFrame:CGRectInset(r, 1, 1)];
        labels[i].textAlignment = NSTextAlignmentCenter;
        labels[i].font = [UIFont fontWithName:@"Helvetica Neue" size:cellSize.height];
        labels[i].backgroundColor = NORMALCOLOR;
        int t;
        if (!scrollingHorizontal)
            t = touchedCol*NUMROWS + i % numItems;
        else
            t = (i % numItems)*NUMROWS + touchedRow;
        labels[i].text = [NSString stringWithFormat:@"%c", grid[t].letter];
        [self addSubview:labels[i]];
    }
    
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowOpacity = 0.7;
    self.layer.shadowRadius = 4;
    self.layer.masksToBounds = NO;
    if (!scrollingHorizontal)
        r = CGRectInset(self.bounds, -4, 0);
    else
        r = CGRectInset(self.bounds, 0, -4);
    self.layer.shadowPath = [[UIBezierPath bezierPathWithRect:r] CGPath];
    
    return self;
}

-(void)saveDataScrolledBy:(int)delta {
    char temp[numItems];
    int i, t;
    
    if (delta < 0)
        delta = numItems - (-delta % numItems);
    for (i=0; i<numItems; i++)
        temp[(i+delta)%numItems] = [labels[i].text characterAtIndex:0];
    for (i=0; i<numItems; i++) {
        if (!scrollingHorizontal)
            t = touchedCol*NUMROWS + i;
        else
            t = i*NUMROWS + touchedRow;
        grid[t].letter = temp[i];
    }
}
@end

@implementation STSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cellSize.width = _gridView.frame.size.width / NUMCOLS;
    cellSize.height = _gridView.frame.size.height / NUMROWS;
    _gridView.parent = self;
    [_gridView createGrid];
    [self initGame];
}
- (void)viewDidLayoutSubviews {
    
}
- (IBAction)initGame {
    self.score = 0;
    for (int i=0; i<GRIDSIZE; i++) {
        grid[i].highlighted = NO;
        grid[i].letter = [GameLogic getNextLetter];
        [_gridView setLetterAtIndex:i];
    }
    [GameLogic countGridLetters];
    _lastWord.text = @"";
    do {
        int idx = arc4random() % (allWords.count/2-2753) + 2753;
        wordToFind = [allWords objectAtIndex:idx*2];
        if (!wordToFind)
            wordToFind = @"PITON";
        else
            wordToFind = [wordToFind uppercaseString];
    } while (![GameLogic wordCanBePuzzled]);
    _labelWordToFind.text = wordToFind;
    isScrolling = NO;
    scroller = nil;
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapField:)];
    [_gridView addGestureRecognizer:tapGesture];
    [self checkAfterPush];
}


CGPoint prevTouch;
int prevCol, prevRow;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:_gridView];
    prevTouch = p;
    touchedCol = prevCol = p.x / cellSize.width;
    touchedRow = prevRow = p.y / cellSize.height;
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:_gridView];
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
            scroller = [[STSScrollView alloc] initWithFrame:_gridView.bounds];
            [_gridView addSubview:scroller];
        }
    }
    else {
        if (scrollingHorizontal)
            scroller.center = CGPointMake(scroller.center.x + p.x-prevTouch.x, scroller.center.y);
        else
            scroller.center = CGPointMake(scroller.center.x, scroller.center.y + p.y-prevTouch.y);
        prevTouch = p;
    }
    prevCol = col;  prevRow = row;
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (scroller) {
        [UIView animateWithDuration:FLASHTIME animations:^{
            CGRect r = scroller.frame;
            if (scrollingHorizontal)
                r.origin.x = round(r.origin.x/cellSize.width)*cellSize.width;
            else
                r.origin.y = round(r.origin.y/cellSize.height)*cellSize.height;
            scroller.frame = r;
        }
        completion:^(BOOL finished) {
            if (finished) {
                if (scrollingHorizontal)
                    [scroller saveDataScrolledBy:prevCol - touchedCol];
                else
                    [scroller saveDataScrolledBy:prevRow - touchedRow];
                [scroller removeFromSuperview];
                scroller = nil;
                isScrolling = NO;
                [self checkAfterPush];
            }
        }];
    }
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

-(void)tapField:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:_gridView];
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
        else if ([cascadeToFold containsObject:@(idx)])
            [self flashCascade:cascadeToFold];
    }
}

-(void)checkAfterPush {
    for (int i=0; i<GRIDSIZE; i++)
        [_gridView setLetterAtIndex:i];
    [GameLogic findCascades];
    /*NSArray **/cascadeToFold = [GameLogic getCascadeToFold];
    for (int i=0; i<GRIDSIZE; i++) {
        grid[i].highlighted = [cascadeToFold containsObject:@(i)];
        [_gridView setLetterAtIndex:i];
    }
    for (NSArray *c in Cascads)
        if (![c isEqualToArray:cascadeToFold])
            for (NSNumber *n in c)
                [_gridView halfHighlight:[n intValue]];
    for (NSNumber *n in cascadeToFold)
        [_gridView setLetterAtIndex:[n intValue]];

    [GameLogic countGridLetters];
    if (![GameLogic wordCanBePuzzled]) {
        _labelWordToFind.text = @"---";
    }
    else
        _labelWordToFind.text = wordToFind;
    //if (cascadeToFold)
      //  [self flashCascade:cascadeToFold];
}

-(void)flashCascade:(NSArray *)cascade {
    [_gridView flashCascade:cascade];
    self.score += [GameLogic calcCascadeScore:cascade];
    _lastWord.text = @"";
    for (NSNumber *n in cascade) {
        int i = [n intValue];
        _lastWord.text = [NSString stringWithFormat:@"%@%c", _lastWord.text, grid[i].letter];
        grid[i].letter = 0;
        grid[i].highlighted = NO;
    }
}

-(void)setScore:(NSInteger)score {
    _score = score;
    _labelScore.text = [NSString stringWithFormat:@"%d", score];
}
@end
