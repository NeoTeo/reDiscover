//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "TGSongPool.h"

// Temporarily need to import this until we can use the Swift MainViewController.
#import "TGMainViewController.h"

// SweetSpotServerIO needs to know about the UploadedSSData class
#import "UploadedSSData.h"

// Fingerprinter needs to know about chromaprint.
//#import "chromaprint.h"

// For songUUID
#import "TGSongProtocol.h"

//#import "NSImage+TGHashId.h"

#import <CommonCrypto/CommonCrypto.h>

// Used by TimelinePopover
#import "TGTimelineSliderCell.h"


//TMP - delete this and just use TimelinePopover instead once this works.
#import "TGSongTimelineViewController.h"
#import "TGSongInfoViewController.h"