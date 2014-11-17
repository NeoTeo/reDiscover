//
//  NSImage+TGHashId.m
//  reDiscover
//
//  Created by Teo on 28/10/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import "NSImage+TGHashId.h"

#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSImage (TGHashId)

@dynamic hashId;

/// Guaranteed to be automatically invoked by the obj-c runtime during class initialization.
+ (void)load {
    
    static dispatch_once_t onceToken;
    
    // Ensure this is only ever called once.
    dispatch_once(&onceToken, ^{
        //Class class = [self class];
        
        // When swizzling a class method, use the following:
        Class class = object_getClass((id)self);

        [self swizzleSelector:@selector(imageNamed:) withSelector:@selector(tgImageNamed:) forClass:class];
        
        class = [self class];
        [self swizzleSelector:@selector(initWithData:) withSelector:@selector(tgInitWithData:) forClass:class];
        [self swizzleSelector:@selector(initWithContentsOfURL:) withSelector:@selector(tgInitWithContentsOfURL:) forClass:class];
        
//        SEL originalSelector = @selector(imageNamed:);
//        SEL swizzledSelector = @selector(tgImageNamed:);
//        
//        Method originalMethod = class_getInstanceMethod(class, originalSelector);
//        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
//        
//        BOOL didAddMethod =
//        class_addMethod(class,
//                        originalSelector,
//                        method_getImplementation(swizzledMethod),
//                        method_getTypeEncoding(swizzledMethod));
//        
//        if (didAddMethod) {
//            class_replaceMethod(class,
//                                swizzledSelector,
//                                method_getImplementation(originalMethod),
//                                method_getTypeEncoding(originalMethod));
//        } else {
//            method_exchangeImplementations(originalMethod, swizzledMethod);
//        }
    });
}

+(void)swizzleSelector:(SEL)originalSel withSelector:(SEL)swizzledSel forClass:(Class)theClass {
    Method originalMethod = class_getInstanceMethod(theClass, originalSel);
    Method swizzledMethod = class_getInstanceMethod(theClass, swizzledSel);
    
    BOOL didAddMethod =
    class_addMethod(theClass,
                    originalSel,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(theClass,
                            swizzledSel,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+(instancetype)tgImageNamed:(NSString*)name {

    NSImage* theImage = [self tgImageNamed:name];
    if (theImage == nil) { return nil; }
    
    // do stuff here to hash the image and store it.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        
        [theImage generateHashForImage:theImage withHandler:^(NSString *theHash) {
            [theImage setHashId:theHash];
            NSLog(@"tgImageNamed Hashhandler: %@",theHash);
        }];
    });
    return theImage;
}

- (instancetype)tgInitWithData:(NSData *)data {
    NSImage* theImage = [self tgInitWithData:data];
    if (theImage == nil) { return nil; }
    
    // do stuff here to hash the image and store it.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        
        [theImage generateHashForImage:theImage withHandler:^(NSString *theHash) {
            [theImage setHashId:theHash];
            NSLog(@"tgInitWithData Hashhandler: %@",theHash);
        }];
    });
    
    return theImage;
}

- (instancetype)tgInitWithContentsOfURL:(NSURL *)url {
    NSImage* theImage = [self tgInitWithContentsOfURL:url];
    if (theImage == nil) { return nil; }
    
    // do stuff here to hash the image and store it.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        
        [theImage generateHashForImage:theImage withHandler:^(NSString *theHash) {
            [theImage setHashId:theHash];
            NSLog(@"tgInitWithContentsOfURL Hashhandler: %@",theHash);
        }];
    });
    
    return theImage;
}


- (void)generateHashForImage:(NSImage*)theImage withHandler:(void (^)(NSString *))hashHandler {

    unsigned char result[CC_MD5_DIGEST_LENGTH];
    NSData *imageData = [theImage TIFFRepresentation];
    CC_MD5([imageData bytes], (unsigned int)[imageData length], result);
    
    // A bit dangerous since this assumes that the MD5 digest length is 16. Assert that it is.
    assert(CC_MD5_DIGEST_LENGTH == 16);
    
    NSString *imageHash = [NSString stringWithFormat:
                           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    
    hashHandler(imageHash);
}


- (void)setHashId:(NSString *)hashId {
    objc_setAssociatedObject(self, @selector(hashId), hashId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString*)hashId {
    return objc_getAssociatedObject(self, @selector(hashId));
}

- (void)hashIdWithHandler:(void (^)(NSString *))hashHandler {
    if ([self hashId] == nil) {
        [self generateHashForImage:self withHandler:hashHandler];
    } else {
        hashHandler([self hashId]);
    }
    
}

@end
