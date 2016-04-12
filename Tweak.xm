#import <iMoMacros.h>
#import <Photos/Photos.h>

extern "C" NSString *PLLocalizedFrameworkString(NSString *key, NSString *comment);

#define ACTION_ID @"com.imokhles.PUPreviewActionController.wallpaper"

@protocol PLWallpaperImageViewControllerDelegate <NSObject>
- (void)wallpaperImageViewControllerDidCancel:(id)arg1;
- (void)wallpaperImageViewControllerDidFinishSaving:(id)arg1;
- (void)wallpaperImageViewControllerDidCropWallpaper:(id)arg1;
@end

@interface PUWallpaperNavigationController : UINavigationController

- (unsigned int)supportedInterfaceOrientations;

@end

@interface PLUIImageViewController : UIViewController
- (void)setAllowsEditing:(BOOL)arg1;
@end

@interface PLUIEditImageViewController : PLUIImageViewController 
- (void)setDelegate:(id)arg1;
@end

@interface PLWallpaperImageViewController : PLUIEditImageViewController
- (void)setSaveWallpaperData:(BOOL)arg1;
@end

@interface PLStaticWallpaperImageViewController : PLWallpaperImageViewController

- (id)_wallPaperPreviewControllerForAsset:(id)arg1;
- (id)initWithUIImage:(id)arg1;
- (void)setWallpaperForLocations:(int)arg1;
- (id)wallpaperImage;

@end

@interface PUPreviewIdentifiedAction : UIPreviewAction
- (id)actionIdentifier;
- (void)setActionIdentifier:(id)arg1;
@end

@interface PUAssetReference : NSObject
@end

@interface PUViewModel : NSObject
@end

@interface PUBrowsingViewModel : PUViewModel
@property (nonatomic, retain) PUAssetReference *currentAssetReference;
@end

@interface PUBrowsingSession : NSObject
@property (nonatomic, retain) PUBrowsingViewModel *viewModel;
@end

@interface PUPreviewActionController : NSObject
@property (nonatomic, retain) PUBrowsingSession *browsingSession;
- (void)_notifiyDelegateOfIdentifiedAction:(id)arg1;
@end

@interface PUPhotosDataSource : NSObject
- (void)stopForceIncludingAllAssets;
- (NSIndexPath *)indexPathForAssetReference:(PUAssetReference *)arg1;
- (PHAsset *)assetAtIndexPath:(NSIndexPath *)arg1;
@end

@interface PUPhotosGridViewController : UICollectionViewController <PLWallpaperImageViewControllerDelegate>
@property (nonatomic, retain) PUPhotosDataSource *photosDataSource;
- (void)ppsw_setAsWallpaper;
@end

@interface PUOneUpViewController : UIViewController
@property (nonatomic, readonly) PUPreviewActionController *previewActionController;
- (void)ppsw_setAsWallpaperWithAction:(PUPreviewIdentifiedAction *)action;
@end

static PUAssetReference *popedAssetReference;

%hook PUOneUpViewController

- (id)previewActionItems {

	NSArray *currentActions = %orig;
	PUPreviewIdentifiedAction *setAsWallpaper = [objc_getClass("PUPreviewIdentifiedAction") actionWithTitle:PLLocalizedFrameworkString(@"USE_AS_WALLPAPER", @"") style:0 handler:^(UIPreviewAction *action, UIViewController *previewViewController) {
        popedAssetReference = self.previewActionController.browsingSession.viewModel.currentAssetReference;
        [self ppsw_setAsWallpaperWithAction:(PUPreviewIdentifiedAction *)action];
    }];
    [setAsWallpaper setActionIdentifier:ACTION_ID];
    NSArray *newActions = [[NSArray alloc] initWithObjects:setAsWallpaper, nil];
    currentActions = [currentActions arrayByAddingObjectsFromArray:newActions];
	return currentActions;
}
%new
- (void)ppsw_setAsWallpaperWithAction:(PUPreviewIdentifiedAction *)action {
	// set as wallpaper
	[self.previewActionController _notifiyDelegateOfIdentifiedAction:action];
}
%end

%hook PUPhotosGridViewController
- (void)previewActionController:(id)arg1 didDismissWithIdentifiedAction:(PUPreviewIdentifiedAction *)arg2 {
	if ([arg2.actionIdentifier isEqualToString:ACTION_ID]) {
		[self ppsw_setAsWallpaper];
	} else {
		%orig;
	}
}
%new
- (void)ppsw_setAsWallpaper {
	PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;

	[self.photosDataSource stopForceIncludingAllAssets];
	NSIndexPath *currentIndexPath = [self.photosDataSource indexPathForAssetReference:popedAssetReference];
	PHAsset *asset = [self.photosDataSource assetAtIndexPath:currentIndexPath];

	[[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (imageData) {
            PLStaticWallpaperImageViewController *wallpaperViewController = [[objc_getClass("PLStaticWallpaperImageViewController")  alloc] initWithUIImage:[UIImage imageWithData:imageData]];        
	        [wallpaperViewController setAllowsEditing:YES];
	        [wallpaperViewController setSaveWallpaperData:YES];
	        [wallpaperViewController setDelegate:self];

	        PUWallpaperNavigationController *wallpaperActivityViewController = [[objc_getClass("PUWallpaperNavigationController") alloc] initWithRootViewController:wallpaperViewController];
	        [self presentViewController:wallpaperActivityViewController animated:YES completion:nil];
        }
    }];


}
%new
- (void)wallpaperImageViewControllerDidCancel:(PLStaticWallpaperImageViewController *)arg1 {

    [arg1 setDelegate:nil];
    [arg1.navigationController dismissViewControllerAnimated:YES completion:nil];
}
%new
- (void)wallpaperImageViewControllerDidFinishSaving:(PLStaticWallpaperImageViewController *)arg1 {
    [arg1 setDelegate:nil];
    [arg1.navigationController dismissViewControllerAnimated:YES completion:nil];
}
%new
- (void)wallpaperImageViewControllerDidCropWallpaper:(PLStaticWallpaperImageViewController *)arg1 {
    return;
}

%end
