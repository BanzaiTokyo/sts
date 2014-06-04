//
//  STSViewController.m
//  SlideToSpell
//
//  Created by Toxa on 22/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "AudioToolbox/AudioToolbox.h"
#import "STSGameViewController.h"

#define NORMALCOLOR [UIColor colorWithWhite:224/255.0 alpha:1.0]
#define HIGHLIGHTCOLOR [UIColor colorWithRed:230/255.0 green:163/255.0 blue:239/255.0 alpha:1.0]
#define SECONDARYCOLOR [UIColor colorWithRed:126/255.0 green:147/255.0 blue:209/255.0 alpha:1.0]
#define FLASHTIME 0.3
#define FLASHSCALEFACTOR 2
#define FALLTIME 0.6

const unsigned long letterColor[10] = {0x17417f, 0x2b8e87, 0x08874a, 0x859b29, 0xce8817, 0xff7776, 0x974ce5, 0xde06e5, 0xbd0006, 0x6b0000};

CGSize screenSize, cellSize;

int touchedRow, touchedCol;
BOOL scrollingHorizontal, fallSeveralColumns;

@interface STSGameViewController () {
    BOOL isScrolling, lettersFalling, paused;
    NSTimeInterval gameTime;
    STSScrollView *scroller;
    UITapGestureRecognizer *tapGesture;
    NSTimer *timer;
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
    labels[idx].font = [UIFont fontWithName:@"BanzaiWordsFont-Bold" size:cellSize.height];
    UILabel *number = [[UILabel alloc] initWithFrame:CGRectMake(r.size.width*0.65, r.size.height*0.1, r.size.width*0.31, r.size.height*0.25)];
    number.textAlignment = NSTextAlignmentRight;
    [labels[idx] addSubview:number];
    [self addSubview:labels[idx]];
}

-(void)setLetterAtIndex:(int)idx {
    if (grid[idx].highlighted)
        labels[idx].backgroundColor = HIGHLIGHTCOLOR;
    else
        labels[idx].backgroundColor = NORMALCOLOR;
    labels[idx].text = [NSString stringWithFormat:@"%c", grid[idx].letter];
    UILabel *number = labels[idx].subviews[0];
    if (grid[idx].letter >= 65) {
        int n = defLetterScore[grid[idx].letter-65];
        number.text = [NSString stringWithFormat:@"%d", n];
        number.textColor = [UIColor colorWithRed:(letterColor[n] >> 16)/255.0 green:((letterColor[n] >> 8) & 255)/255.0 blue:(letterColor[n] & 255)/255.0 alpha:1.0];
    }
    else
        number.text = @"";
}

-(void)halfHighlight:(int)idx {
    labels[idx].backgroundColor = SECONDARYCOLOR;
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
                minX = MIN(i/NUMROWS, minX);
                maxX = MAX(i/NUMROWS, maxX);
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
        labels[i].font = [UIFont fontWithName:@"BanzaiWordsFont-Bold" size:cellSize.height];
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

@implementation STSGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cellSize.width = _gridView.frame.size.width / NUMCOLS;
    cellSize.height = _gridView.frame.size.height / NUMROWS;
    _gridView.parent = self;
    [_gridView createGrid];
    _lastWord.font = [UIFont fontWithName:@"BanzaiWordsFont-Bold" size:30];
    _labelTime.font = [UIFont fontWithName:@"BanzaiWordsFont-Bold" size:30];
    _labelScore.font = [UIFont fontWithName:@"BanzaiWordsFont-Bold" size:30];
    CGRect r = _gridView.frame;
    r.size.height = 0;
    _pauseView.frame = r;
}
- (void)viewWillAppear:(BOOL)animated {
    [self initGame];
}
- (IBAction)initGame {
    score = 0;
    _labelScore.text = @"0";
    [wordsLog removeAllObjects];
    lettersFalling = YES;
        do {
            for (int i=0; i<GRIDSIZE; i++) {
                grid[i].highlighted = NO;
                grid[i].letter = [GameLogic getNextLetter];
                [_gridView setLetterAtIndex:i];
            }
            [GameLogic findCascades];
        } while (Cascads.count > 0);
        lettersFalling = NO;
    _lastWord.text = @"";
    isScrolling = NO;
    scroller = nil;
    if (!tapGesture) {
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapField:)];
        [_gridView addGestureRecognizer:tapGesture];
    }
    _labelTime.textColor = [UIColor blackColor];
    if (zenMode)
        _labelTime.text = @"---";
    else {
        gameTime = ROUNDTIME+1;
        [self tick]; //to display gameTime
        if (!zenMode)
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    }
    paused = NO;
    _pauseView.hidden = YES;
}


CGPoint prevTouch;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ((gameTime <= 0 && !zenMode) || lettersFalling)
        return;
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:_gridView];
    prevTouch = p;
    touchedCol = p.x / cellSize.width;
    touchedRow = p.y / cellSize.height;
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if ((gameTime <= 0 && !zenMode) || lettersFalling)
        return;
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:_gridView];
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
                CGFloat delta;
                if (scrollingHorizontal)
                    delta = (scroller.frame.origin.x + _gridView.bounds.size.width)/cellSize.width;
                else
                    delta = (scroller.frame.origin.y + _gridView.bounds.size.height)/cellSize.height;
                [scroller saveDataScrolledBy:round(delta)];
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
    if ((gameTime <= 0 && !zenMode) || lettersFalling)
        return;
    if (isScrolling)
        return;
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

    if (cascadeToFold)
        [self flashCascade:cascadeToFold];
    else
        lettersFalling = NO;
}

-(void)flashCascade:(NSArray *)cascade {
    lettersFalling = YES;
    score += [GameLogic calcCascadeScore:cascade];
    highScore = MAX(score, highScore);
    _labelScore.text = [NSString stringWithFormat:@"%d", score];
    _lastWord.text = @"";
    for (NSNumber *n in cascade) {
        int i = [n intValue];
        _lastWord.text = [NSString stringWithFormat:@"%@%c", _lastWord.text, grid[i].letter];
        grid[i].letter = 0;
        grid[i].highlighted = NO;
    }
    if (_lastWord.text.length) {
        if (wordsLog.count > MAXWORDSLOGSIZE)
            [wordsLog removeObjectAtIndex:0];
        [wordsLog addObject:_lastWord.text];
    }
    [_gridView flashCascade:cascade];
}

-(void)tick {
    if (paused)
        return;
    gameTime -= 1.0;
    if (gameTime < 0)
        gameTime = 0;
    long min = (long)gameTime / 60;    // divide two longs, truncates
    long sec = (long)gameTime % 60;    // remainder of long divide
    _labelTime.text = [NSString stringWithFormat:@"%02ld:%02ld", min, sec];
    if (gameTime < 30)
        _labelTime.textColor = [UIColor colorWithRed:90/255.0 green:0 blue:0 alpha:1.0];
    if (gameTime <= 0 && !lettersFalling) {
        if (isScrolling)
            [self touchesEnded:nil withEvent:nil];
        [timer invalidate];
        timer = nil;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game over" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [av show];
    }
}
- (IBAction)pauseGame {
    if (!zenMode) {
        if (paused)
            return;
        paused = YES;
        _pauseView.hidden = NO;
        _btnPause.enabled = NO;
        [_btnPause setTitleColor: [UIColor lightGrayColor] forState:UIControlStateNormal];
        [((UITableViewController *)self.childViewControllers[0]).tableView reloadData];
        CGRect r = _pauseView.frame;
        r.size.height = self.view.frame.size.height - r.origin.y;
        [UIView animateWithDuration:0.5 animations:^{
            _pauseView.frame = r;
        }];
        return;
    }
}
-(void)stopGame {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    if (!lettersFalling) {
        if (isScrolling)
            [self touchesEnded:nil withEvent:nil];
        if (highScore > score) {
            [[NSUserDefaults standardUserDefaults] setInteger:highScore forKey:@"highScore"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        for (int i=0; i<GRIDSIZE; i++) {
            grid[i].highlighted = NO;
            grid[i].letter = 32;
            [_gridView setLetterAtIndex:i];
        }
        [self performSegueWithIdentifier:@"viewLog" sender:nil];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self stopGame];
}
- (IBAction)closePause:(id)sender {
    [_btnPause setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    CGRect r = _pauseView.frame;
    r.size.height = 0;
    [UIView animateWithDuration:0.5 animations:^{
        _pauseView.frame = r;
    } completion:^(BOOL finished) {
        if (finished) {
            _pauseView.hidden = YES;
            paused = NO;
            _btnPause.enabled = YES;
        }
    }];
}

- (IBAction)returnActionForSegue:(UIStoryboardSegue *)returnSegue {
}

@end
