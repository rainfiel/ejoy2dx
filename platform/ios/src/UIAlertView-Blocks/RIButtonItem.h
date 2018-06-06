//
//  RIButtonItem.h
//  Shibui
//
//  Created by Jiva DeVoe on 1/12/11.
//  Copyright 2011 Random Ideas, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RIButtonItem : NSObject
@property (strong, nonatomic) NSString *label;
@property (copy, nonatomic) void (^action)(UIAlertView *);

+(id)item;
+(id)itemWithLabel:(NSString *)inLabel;
@end

