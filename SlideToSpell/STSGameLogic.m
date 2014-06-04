//
//  STSGameLogic.m
//  SlideToSpell
//
//  Created by Toxa on 22/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "STSGameLogic.h"

int defLetterScore[ALPHA_SIZE] = {/*A*/1, /*B*/3, /*C*/3, /*D*/3, /*E*/1, /*F*/4, /*G*/3, /*H*/4, /*I*/1, /*J*/9, /*K*/5, /*L*/2, /*M*/3, /*N*/1, /*O*/1, /*P*/3, /*Q*/10, /*R*/1, /*S*/1, /*T*/1, /*U*/2, /*V*/4, /*W*/6, /*X*/7, /*Y*/4, /*Z*/9};

@implementation Trie
-(id)init {
  self = [super init];
  count = 0;
  word = nil;
  for (int i=0; i<ALPHA_SIZE; i++)
    children[i] = nil;
  return self;
}
@end

int board[BOARDSIZE];
int children[4];

@implementation GameLogic
+(void) initialize {
  memcpy(letterScore, defLetterScore, sizeof(defLetterScore));
  
  children[0] = -BOARDROWS;  children[1] = -1;
  children[2] = 1;  children[3] = BOARDROWS;
  if (!Cascads) {
    Cascads = [[NSMutableArray alloc] init];
    Words = [[NSMutableArray alloc] init];
    wordsLog = [[NSMutableArray alloc] init];
  }
  [GameLogic buildTrie];
}
+(void) deinitialize {
  Cascads = nil;
  Words = nil;
}

+(char) getNextLetter {
  char x = arc4random() % 83;
  char freq[83] = {
    'A', 'A', 'A', 'A', 'A', 'B', 'B',
    'B', 'C', 'C', 'C', 'D', 'D', 'D', 'E', 'E', 'E', 'E', 'E', 'E',
    'F', 'F',
    'F', 'G', 'G', 'G', 'G', 'H', 'H', 'H', 'I', 'I', 'I', 'I', 'I', 'J', 'J', 'K', 'K', 'L', 'L', 'L',
    'L', 'M', 'M', 'M', 'N', 'N', 'N', 'N', 'O', 'O', 'O', 'O', 'P', 'P', 'P', 'Q',
    'R', 'R', 'R', 'R', 'S', 'S', 'S', 'S', 'T', 'T', 'T', 'T', 'U', 'U', 'U',
    'V', 'V', 'W', 'W', 'X', 'X', 'Y', 'Y', 'Z', 'Z'};
  x = freq[x];
  return x;
}

+(BOOL)range:(int) n {
  return (n >= 0) && (n < GRIDSIZE);
}

//=============== cascade finding logic =================

//add word to Trie
+(void) insertWord:(NSString *)word {
  Trie* p = dict;
  int i;
  
  for(i = 0; i < [word length]; i++){
    int letter = [word characterAtIndex:i] - 'a'; //convert characters to ints: a=0 z=25
    
    /*//combine 'qu' into single cube represented by 'q'
    if( ('q' == [word characterAtIndex:i]) && ('u' == [word characterAtIndex:i+1]) )
      i++;*/
    
    p->count++; //track how many words use this prefix
    
    if( !p->children[letter] )
      p->children[letter] = [[Trie alloc] init];
    
    p = p->children[letter];
  }
  
  p->word = [NSString stringWithString:word]; //the last node completes the word, save it here
}

// load dictionary into trie
+(void) buildTrie {

  NSLog(@"loading dictionary");
  NSString *fileString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"words" ofType:@"txt"] encoding:NSUTF8StringEncoding error: nil];
  allWords = [NSArray arrayWithArray:[fileString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
  
  dict = [[Trie alloc] init];
  
  NSLog(@"parsing dictionary of %i words", [allWords count]);
  for (NSString *word in allWords)
  [GameLogic insertWord: word];
  NSLog(@"trie parsed");
}

+(void)descend:(int)cubeIndex :(Trie*)p :(NSMutableArray *)searched :(NSMutableArray *)sequence :(int)depth :(BOOL)directionDown {
  depth++;
  NSMutableArray *dsearched = [NSMutableArray arrayWithArray:searched];
  NSMutableArray *dsequence = [NSMutableArray arrayWithArray:sequence];
  
  if (board[cubeIndex] < 0 || board[cubeIndex] > ALPHA_SIZE) return;
  p = p->children[board[cubeIndex]];
  if (!p) return;
  
  int realIndex = cubeIndex  / BOARDROWS - 1;
  realIndex = realIndex * NUMROWS + cubeIndex % BOARDROWS - 1;

  if (p->count) { //is this a valid prefix? Are there any remaining words that use it?
    [dsearched replaceObjectAtIndex:cubeIndex withObject:[NSNumber numberWithBool:YES]]; //mark this cube as used
    [dsequence addObject:[NSNumber numberWithInt:realIndex]];
    int child = cubeIndex + (directionDown ? 1 : BOARDROWS);
    if ((board[child] != BORDER) && ![[dsearched objectAtIndex:child] boolValue]) //faster to check here
          [GameLogic descend:child :p :dsearched :dsequence :depth :directionDown];
  }
  
  if (p->word && (depth >= MINWORDLENGTH)) {
    NSNumber *n = [NSNumber numberWithInt:realIndex];
    if (![dsequence containsObject:n])
      [dsequence addObject:n];
    NSSet *s = [NSSet setWithArray:dsequence];
    BOOL b = NO;
    for(NSArray *a in Cascads)
      b = b | [s isEqualToSet:[NSSet setWithArray:a]];
    if (!b) {
      //NSLog(@"%@", dsequence);
      //NSLog(@"%@", p->word);

      [Cascads addObject:dsequence];
      [Words addObject:p->word];
    }
  }
}

+(void) buildBoard {
  //add border
  int j = 0;
  for(int i = 0; i < BOARDSIZE; i++){
    if( (i < BOARDROWS) ||           //top
       ((i+1) % BOARDROWS == 0) ||      //right
       (i > BOARDROWS * (NUMCOLS +1)) ||   //bot
       (i % BOARDROWS == 0)) {             //left
      board[i] = BORDER;
    }else{
        board[i] = grid[j].letter - 65;
      j++;
    }
  }
}

+(void)findCascades {
  [Cascads removeAllObjects];
  [Words removeAllObjects];

  [GameLogic buildBoard];
  Trie* p = dict;
  NSMutableArray *searched = [NSMutableArray arrayWithCapacity:BOARDSIZE]; //cubes should be used only once per word
  NSMutableArray *sequence = [NSMutableArray arrayWithCapacity:0];
  
  //initialize searched to false for all cubes on the board
  for(int i = 0; i < BOARDSIZE; i++)
    [searched addObject:[NSNumber numberWithBool:NO]];
  
  for(int i = BOARDROWS+1; i < BOARDSIZE-BOARDROWS-1; i++) {
      if (board[i] != BORDER) {
        [GameLogic descend:i :p :searched :sequence :0 :YES]; //DFS
        [GameLogic descend:i :p :searched :sequence :0 :NO]; //DFS
      }
  }
    //NSLog(@"%d words found", [Cascads count]);
}

+(int)calcCascadeScore:(NSArray*)word {
    int result = 0;
    for (NSNumber *n in word)
    result += letterScore[grid[[n intValue]].letter-65];
    if (word.count > MINWORDLENGTH)
        result *= word.count;
    return result;
}

+(void)countGridLetters {
    memset(gridLetterCount, 0, ALPHA_SIZE);
    for (int i=0; i<GRIDSIZE; i++)
        gridLetterCount[grid[i].letter-65]++;
}

+(int)longestStraightSegment:(NSArray *)cascade {
    int i, result = 0, cell1, cell2, row, col, prevRow, prevCol, isHorizontal;
    if ([cascade count] < 2)
        return 1;
    cell1 = [cascade[0] intValue];  cell2 = [cascade[1] intValue];
    prevRow = cell1 % NUMROWS;  row = cell2 % NUMROWS;
    prevCol = cell1 / NUMROWS;  col = cell2 / NUMROWS;
    isHorizontal = prevRow == row;
    cell1 = cell2;
    prevRow = row;  prevCol = col;
    i = result = 2;
    while (i < [cascade count]) {
        cell2 = [cascade[i] intValue];
        row = cell2 % NUMROWS;  col = cell2 / NUMROWS;
        if ((row == prevRow && isHorizontal) || (col == prevCol && !isHorizontal))
            result++;
        else {
            result = 2;
        }
        cell1 = cell2;
        isHorizontal = prevRow == row;
        prevRow = row;  prevCol = col;
        i++;
    }
    return result;
}

+(NSArray *)getCascadeToFold {
    if (![Cascads count])
        return nil;
    if ([Cascads count] == 1)
        return Cascads[0];
    
    NSComparator sorter = ^NSComparisonResult(id obj1, id obj2) {
        NSUInteger c1 = [obj1 count], c2 = [obj2 count];
        if (c1 > c2)
            return NSOrderedDescending;
        else if (c1 < c2)
            return NSOrderedAscending;
        else {
            c1 = [obj1[0] intValue]; c2 = [obj2[0] intValue];
            int row1 = c1 % NUMROWS, row2 = c2 % NUMROWS;
            if (row1 == row2) {
                if (c1 > c2)
                    return NSOrderedAscending;
                else if (c1 < c2)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
            }
            else if (row1 > row2)
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }
    };
    [Cascads sortUsingComparator:sorter];
    NSArray *c1 = Cascads[0], *c2 = Cascads[1], *result;
    if ([c1 count] < [c2 count]) {
        NSLog(@"shortest %@", c1);
        return c1;
    }
    int row1 = [c1[0] intValue], row2 = [c2[0] intValue], col1, col2;
    col1 = row1 / NUMROWS;  col2 = row2 / NUMROWS;
    row1 = row1 % NUMROWS;  row2 = row2 % NUMROWS;
    if (row1 == row2) {
        if (col1 == col2) {
            int ls1 = [self longestStraightSegment:c1], ls2 = [self longestStraightSegment:c2];
            if (ls1 >= ls2)
                result = c1;
            else
                result = c2;
            NSLog(@"same begin point, longest segment %d %@", MAX(ls1, ls2), result);
        }
        else {
            if (col1 < col2)
                result = c1;
            else if (col2 < col1)
                result = c2;
            NSLog(@"same row, leftmost column %d", MIN(col1, col2));
        }
    }
    else {
        if (row1 > row2)
            result = c1;
        else if (row2 > row1)
            result = c2;
        NSLog(@"lowest %@", result);
    }
    return result;
}

@end
