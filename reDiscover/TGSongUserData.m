//
//  TGSongUserData.m
//  Proto3
//
//  Created by Teo Sartori on 13/05/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSongUserData.h"

// Private declarations of TGSongUserData ivars.
//@interface TGSongUserData ()
//
//@property NSString *primitiveSongURL;
//@property NSString *primitiveSongUUID;
//@property NSNumber *primitiveSongUserSweetSpot;
//
//@end


@implementation TGSongUserData

//@dynamic songURL, songUUID, songUserSweetSpot, primitiveSongURL, primitiveSongUUID, primitiveSongUserSweetSpot;
@dynamic songURL, songFingerPrint, songUUID, songUserSweetSpot,songSweetSpots;

/*
- (void)setSongURL:(NSString *)anURL {
    NSLog(@"setting songURL %@",anURL);
    self.songURL = anURL;
}

- (NSString *)songURL {
    NSLog(@"returning songURL");
    return self.songURL;
}
 */
// Called on insertion of the object into the managed object context.
//- (void)awakeFromInsert {
//    [super awakeFromInsert];
//    
//    self.pri
//}

//- (void)setNilValueForKey:(NSString *)key {
//    if ([key isEqualToString:@"songURL"]) {
//        self.primitiveSongURL = @"";
//    }
//    else if ([key isEqualToString:@"songUUID"]) {
//        self.primitiveSongUUID = @"";
//    }
//    else if ([key isEqualToString:@"songUserSweetSpot"]) {
//        self.primitiveSongUserSweetSpot = 0;
//    }
//    else
//        [super setNilValueForKey:key];
//}

@end
