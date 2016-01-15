//
//  TGStack.h
//  
//
//  Created by teo on 16/06/14.
//
//

@interface TGStack : NSObject

@property NSMutableArray* items;
@property NSInteger maxSize;

- (id)init;
- (id)initWithSize:(NSInteger)size;

- (void)setSize:(NSInteger)size;
- (void)push:(id)anObject;
- (id)pop;

@end