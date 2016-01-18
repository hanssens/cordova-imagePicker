//
//  SOSPicker.h
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import <Cordova/CDVPlugin.h>


@interface SOSPicker : CDVPlugin < UINavigationControllerDelegate, UIScrollViewDelegate>

@property (copy)   NSString* callbackId;

- (void)getPictures:(CDVInvokedUrlCommand *)command;
- (void)clearSelectedAssets:(CDVInvokedUrlCommand *)command;

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger quality;
@property (nonatomic, assign) NSInteger outputType;

@property (nonatomic, strong) NSArray *previousSelectedAssets;

@end
