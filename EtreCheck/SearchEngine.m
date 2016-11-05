//
//  SearchEngine.m
//  EtreCheck
//
//  Created by Kian Lim on 9/9/16.
//  Copyright © 2016 Etresoft. All rights reserved.
//

#import "SearchEngine.h"

@implementation SearchEngine

+ (SearchEngineType)currentSearchEngine {
	return (SearchEngineType)[[[NSUserDefaults standardUserDefaults] objectForKey: @"searchEngineType"] integerValue];
}

+ (NSString *)searchEngineURL {
	SearchEngineType searchEngineType = [[[NSUserDefaults standardUserDefaults] objectForKey:@"searchEngineType"] integerValue];
	switch (searchEngineType) {
		case SearchEngineTypeYahoo:
			return @"https://search.yahoo.com/search?p=";
			
		case SearchEngineTypeBing:
			return @"https://www.bing.com/search?q=";
			
		case SearchEngineTypeDuckDuckGo:
			return @"https://www.duckduckgo.com/?q=";
			
		case SearchEngineTypeGoogle:
		default:
			return @"https://www.google.com/search?q=";
	}
}

+ (void)setSearchEngineType:(SearchEngineType)searchEngineType {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:searchEngineType] forKey:@"searchEngineType"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
