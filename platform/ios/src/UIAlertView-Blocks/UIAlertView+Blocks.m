//
//  UIAlertView+Blocks.m
//  Shibui
//
//  Created by Jiva DeVoe on 12/28/10.
//  Copyright 2010 Random Ideas, LLC. All rights reserved.
//

#import "UIAlertView+Blocks.h"
#import <objc/runtime.h>

static NSString *RI_BUTTON_ASS_KEY = @"com.random-ideas.BUTTONS";

@implementation UIAlertView (Blocks)

-(id)initWithTitle:(NSString *)inTitle message:(NSString *)inMessage Items:(NSArray *)items {
    RIButtonItem *inCancelButtonItem = [items objectAtIndex:0];
    if((self = [self initWithTitle:inTitle message:inMessage delegate:self cancelButtonTitle:inCancelButtonItem.label otherButtonTitles:nil]))
    {
        int count = [items count];
        int i = 1;
        for (; i < count; ++i) {
            RIButtonItem *item = items[i];
            [self addButtonWithTitle:item.label];
        }
        
        objc_setAssociatedObject(self, (__bridge const void *)RI_BUTTON_ASS_KEY, items, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self setDelegate:self];
    }
    return self;
}

-(id)initWithTitle:(NSString *)inTitle message:(NSString *)inMessage cancelButtonItem:(RIButtonItem *)inCancelButtonItem otherButtonItems:(RIButtonItem *)inOtherButtonItems, ... 
{
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:inCancelButtonItem];
    va_list argumentList;
    if (inOtherButtonItems)
    {
        [items addObject: inOtherButtonItems];
        va_start(argumentList, inOtherButtonItems);
        RIButtonItem *eachItem;
        while((eachItem = va_arg(argumentList, RIButtonItem *)))
        {
            [items addObject: eachItem];
        }
        va_end(argumentList);
    }
    return [self initWithTitle:inTitle message:inMessage Items:items];
}

- (NSInteger)addButtonItem:(RIButtonItem *)item
{	
    NSMutableArray *buttonsArray = objc_getAssociatedObject(self, (__bridge const void *)RI_BUTTON_ASS_KEY);	
	
	NSInteger buttonIndex = [self addButtonWithTitle:item.label];
	[buttonsArray addObject:item];
	
	return buttonIndex;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // If the button index is -1 it means we were dismissed with no selection
    if (buttonIndex >= 0)
    {
        NSArray *buttonsArray = objc_getAssociatedObject(self, (__bridge const void *)RI_BUTTON_ASS_KEY);
        RIButtonItem *item = [buttonsArray objectAtIndex:buttonIndex];
        if(item.action)
            item.action(alertView);
    }
    
    objc_setAssociatedObject(self, (__bridge const void *)RI_BUTTON_ASS_KEY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
