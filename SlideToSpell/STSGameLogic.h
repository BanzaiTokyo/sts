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
#define MINWORDLENGTH 3
#define BOARDROWS (NUMROWS+2)
#define BOARDSIZE (NUMCOLS+2)*BOARDROWS
#define MAXWORDSLOGSIZE 1000
#define ROUNDTIME 120

typedef struct {
    BOOL highlighted;
    char letter;
} GridCell;

GridCell grid[GRIDSIZE];
char gridLetterCount[ALPHA_SIZE]; //char is just for 1-byte size, anyway array value cannot be larger than GRIDSIZE
NSMutableArray *Cascads, *Words, *wordsLog;
NSArray *allWords, *cascadeToFold;
BOOL zenMode;
int score, highScore;

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
+(void)countGridLetters;
+(NSArray *)getCascadeToFold;
@end