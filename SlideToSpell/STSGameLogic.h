//
//  STSGameLogic.h
//  SlideToSpell
//
//  Created by Toxa on 22/05/14.
//  Copyright (c) 2014 Toxa. All rights reserved.
//

#import "Foundation/Foundation.h"

//game constants
#define NUMROWS 10
#define NUMCOLS 5
#define GRIDSIZE NUMROWS*NUMCOLS

#define ALPHA_SIZE 26 //number of letters in our alphabet
#define BORDER ALPHA_SIZE
#define WSIZE = 24 //longest word read in dictionary
#define MINWORDLENGTH 5
#define BOARDROWS (NUMROWS+2)
#define BOARDSIZE (NUMCOLS+2)*BOARDROWS

typedef struct {
    BOOL highlighted;
    char letter;
} GridCell;

GridCell grid[GRIDSIZE];
NSMutableArray *Cascads, *Words, *wordsLog;
int score;

@interface Trie: NSObject {
@public
  Trie *children[ALPHA_SIZE];
  int count; //number of suffixes that share this as a root
  NSString *word; //if this node completes a word, store it here
}
@end
Trie *dict;
int letterScore[ALPHA_SIZE];

@interface GameLogic : NSObject
+(char)getNextLetter;
+(void)findCascades;
+(int)calcCascadeScore:(NSArray*)word;
@end