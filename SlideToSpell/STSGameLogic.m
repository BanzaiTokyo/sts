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
  char x = arc4random() % 98;
  char freq[98] = {
    'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'B',
    'B', 'C', 'C', 'D', 'D', 'D', 'D', 'E', 'E', 'E',
    'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'F',
    'F', 'G', 'G', 'G', 'H', 'H', 'I', 'I', 'I', 'I',
    'I', 'I', 'I', 'I', 'I', 'J', 'K', 'L', 'L', 'L',
    'L', 'M', 'M', 'N', 'N', 'N', 'N', 'N', 'N', 'O',
    'O', 'O', 'O', 'O', 'O', 'O', 'O', 'P', 'P', 'Q',
    'R', 'R', 'R', 'R', 'R', 'R', 'S', 'S', 'S', 'S',
    'T', 'T', 'T', 'T', 'T', 'T', 'U', 'U', 'U', 'U',
    'V', 'V', 'W', 'W', 'X', 'Y', 'Y', 'Z'};
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
  NSArray *a = [NSArray arrayWithArray:[fileString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
  
  dict = [[Trie alloc] init];
  
  NSLog(@"parsing dictionary of %i words", [a count]);
  for (NSString *word in a)
  [GameLogic insertWord: word];
  NSLog(@"trie parsed");
}

+(void)descend:(int)cubeIndex :(Trie*)p :(NSMutableArray *)searched :(NSMutableArray *)sequence :(int)depth {
  depth++;
  NSMutableArray *dsearched = [NSMutableArray arrayWithArray:searched];
  NSMutableArray *dsequence = [NSMutableArray arrayWithArray:sequence];
  
  p = p->children[board[cubeIndex]];
  if (!p) return;
  
  int realIndex = cubeIndex  / BOARDROWS - 1;
  realIndex = realIndex * NUMROWS + cubeIndex % BOARDROWS - 1;

  if (p->count) { //is this a valid prefix? Are there any remaining words that use it?
    [dsearched replaceObjectAtIndex:cubeIndex withObject:[NSNumber numberWithBool:YES]]; //mark this cube as used
    [dsequence addObject:[NSNumber numberWithInt:realIndex]];
    for (int i = 0; i < 4; i++) { //descend to each neighboring cube
      int child = cubeIndex + children[i];
      if ((board[child] != BORDER) && ![[dsearched objectAtIndex:child] boolValue]) //faster to check here
        [GameLogic descend:child :p :dsearched :dsequence :depth];
    }
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
  
  for(int i = 0; i < BOARDSIZE; i++) {
    int t = (i / BOARDROWS+1)*BOARDROWS - i % BOARDROWS - 1;
    if (board[t] != BORDER)
      [GameLogic descend:t :p :searched :sequence :0]; //DFS
  }
}

+(int)calcCascadeScore:(NSArray*)word {
  int result = 0;
  for (NSNumber *n in word)
    result += letterScore[grid[[n intValue]].letter-65];
  return result*word.count;
}

@end
