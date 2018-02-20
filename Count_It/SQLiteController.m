//
//  SQLiteController.m
//  Count_It
//
//  Created by Michael LaRandeau on 5/24/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import "SQLiteController.h"
#import "sqlite3.h"

static int rowCallBack(void *sqlitecontroller, int argc, char **argv, char **azColName) {
    SQLiteController *controller = (__bridge SQLiteController *)(sqlitecontroller);
    int i;
    for (i=0;i<argc;i++) {
        const char *value = argv[i] ? argv[i] : "NULL";
        [controller.results addObject:[NSString stringWithUTF8String:value]];
    }
    return 0;
}

@implementation SQLiteController

-(void)runQuery:(const char*)filePath query:(const char*)query {
    self.results = [[NSMutableArray alloc] init];
    sqlite3 *db;
    char *error = 0;
    if (sqlite3_open(filePath, &db) == 0) {
        sqlite3_exec(db, query, rowCallBack, (__bridge void *)(self), &error);
    }
    
    sqlite3_close(db);
}

-(NSArray *)getAllGames {
    const char *path = "/Users/Shared/GOG.com/Galaxy/Storage/index.db";
    const char *query = "SELECT prod.localpath FROM Products as prod INNER JOIN AvailableGameIDInfo as info ON prod.productId = info.productId";
    [self runQuery:path query:query];
    
    
    return [self results];
}

@end
