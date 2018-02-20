//
//  SQLiteController.h
//  Count_It
//
//  Created by Michael LaRandeau on 5/24/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLiteController : NSObject

@property NSMutableArray *results;

-(void)runQuery:(const char*)filePath query:(const char*)query;
-(NSArray *)getAllGames;

@end
