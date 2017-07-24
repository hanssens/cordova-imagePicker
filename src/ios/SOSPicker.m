//
//  SOSPicker.m
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import "SOSPicker.h"


#import "GMImagePickerController.h"
#import "UIImage+fixOrientation.m"


typedef enum : NSUInteger {
    FILE_URI = 0, // TODO
    BASE64_STRING = 1
} SOSPickerOutputType;

@interface SOSPicker () <GMImagePickerControllerDelegate>
@end

@implementation SOSPicker

@synthesize callbackId;

- (void)getPictures:(CDVInvokedUrlCommand *)command {

    NSDictionary *options = [command.arguments objectAtIndex: 0];

    self.outputType = [[options objectForKey:@"outputType"] integerValue];
    NSString * title = [options objectForKey:@"title"];
    NSString * message = [options objectForKey:@"message"];
    NSInteger maxNumOfAllowedSelectedImages = [[options objectForKey:@"maximumImagesCount"] integerValue];
    if (message == (id)[NSNull null]) {
      message = nil;
    }
    self.width = [[options objectForKey:@"width"] integerValue];
    self.height = [[options objectForKey:@"height"] integerValue];
    self.quality = [[options objectForKey:@"quality"] integerValue];

    self.callbackId = command.callbackId;
    [self launchGMImagePickerWithTitle:title
                               message:message
         maxNumOfAllowedSelectedImages:maxNumOfAllowedSelectedImages];
}

- (void)clearSelectedAssets:(CDVInvokedUrlCommand *)command {
  self.previousSelectedAssets = nil;
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                              callbackId:command.callbackId];
}

- (void)launchGMImagePickerWithTitle:(NSString *) title
                             message:(NSString *) message
       maxNumOfAllowedSelectedImages:(NSInteger)maxNumOfAllowedSelectedImages {

    GMImagePickerController *picker = [[GMImagePickerController alloc] init];
    picker.delegate = self;
    picker.title = title;
    picker.customNavigationBarPrompt = message;
    picker.maxNumOfAllowedSelectedImages = maxNumOfAllowedSelectedImages;
    picker.colsInPortrait = 4;
    picker.colsInLandscape = 6;
    picker.minimumInteritemSpacing = 2.0;
    picker.modalPresentationStyle = UIModalPresentationPopover;

    if (self.previousSelectedAssets != nil && self.previousSelectedAssets.count) {
      [picker.selectedAssets addObjectsFromArray:self.previousSelectedAssets];
      if (picker.displaySelectionInfoToolbar) {
        [picker updateToolbar];
      }
    }

    UIPopoverPresentationController *popPC = picker.popoverPresentationController;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.sourceView = picker.view;

    [self.viewController showViewController:picker sender:nil];
}


#pragma mark - UIImagePickerControllerDelegate


- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User finished picking assets");
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User pressed cancel button");
}

#pragma mark - GMImagePickerControllerDelegate

- (void)assetsPickerController:(GMImagePickerController *)picker
        didFinishPickingAssets:(NSArray *) assetsArray {

    if (picker.maxNumOfAllowedSelectedImages == 1) {
      // special case for single image picker
      // do not cache pre-selected photo because the user will replace them with another one
    } else {
      self.previousSelectedAssets = [[NSArray alloc] initWithArray:assetsArray];
    }

    [picker.presentingViewController dismissViewControllerAnimated:YES
                                                        completion:nil];

    NSLog(@"GMImagePicker: User finished picking assets. Number of selected items is: %lu", (unsigned long) assetsArray.count);

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

        NSMutableArray * result_all = [[NSMutableArray alloc] init];
        CGSize targetSize = CGSizeMake(self.width, self.height);
        CDVPluginResult* result = nil;


        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

        // this one is key
        requestOptions.synchronous = true;

        PHImageManager *manager = [PHImageManager defaultManager];

        for (PHAsset *asset in assetsArray ) {
          // Do something with the asset

          [manager requestImageForAsset:asset
                             targetSize:(self.width == 0 && self.height == 0) ? PHImageManagerMaximumSize : targetSize
                            contentMode:PHImageContentModeDefault
                                options:requestOptions
                          resultHandler:^void(UIImage *image, NSDictionary *info) {
                              if (self.outputType == BASE64_STRING){
                                  [result_all addObject:[UIImageJPEGRepresentation(image.fixOrientation, self.quality/100.0f) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
                              }
                          }];
        }

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                    messageAsArray:result_all];

        [self.viewController dismissViewControllerAnimated:YES
                                                completion:nil];
        [self.commandDelegate sendPluginResult:result
                                    callbackId:self.callbackId];
    });

}

//Optional implementation:
-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker {
  self.previousSelectedAssets = nil;
  [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                               messageAsArray:[[NSMutableArray alloc] init]];;
  [self.commandDelegate sendPluginResult:result
                              callbackId:self.callbackId];
  NSLog(@"GMImagePicker: User pressed cancel button, no photos selected");
}


@end
