//
//  SearchEngine.h
//  EtreCheck
//
//  Created by Kian Lim on 9/9/16.
//  Copyright © 2016 Etresoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SearchEngineType) {
	SearchEngineTypeGoogle,
	SearchEngineTypeYahoo,
	SearchEngineTypeBing,
	SearchEngineTypeDuckDuckGo
};

@interface SearchEngine : NSObject

+ (SearchEngineType)currentSearchEngine;
+ (NSString *)searchEngineURL;
+ (void)setSearchEngineType:(SearchEngineType)searchEngineType;

@end
