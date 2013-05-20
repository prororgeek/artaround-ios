//
//  AddArtViewController.m
//  ArtAround
//
//  Created by Brian Singer on 5/18/13.
//  Copyright (c) 2013 ArtAround. All rights reserved.
//

#import "AddArtViewController.h"
#import "PhotoImageView.h"
#import "EGOImageButton.h"
#import "Photo.h"
#import "PhotoImageView.h"
#import "Art.h"
#import "ArtAroundAppDelegate.h"
#import "AAAPIManager.h"
#import "ArtAnnotation.h"
#import <QuartzCore/QuartzCore.h>
#import "Utilities.h"
#import "SearchItem.h"
#import "ArtParser.h"

@interface AddArtViewController ()
- (void) buttonPressed:(id)sender;
- (void) postButtonPressed;
- (void) categoryButtonPressed;
- (void) eventButtonPressed;
- (void) locationButtonPressed;

- (void)photoUploadCompleted;
- (void)photoUploadFailed;
- (void)photoUploadCompleted:(NSDictionary*)responseDict;
- (void)photoUploadFailed:(NSDictionary*)responseDict;

@end

@implementation AddArtViewController

@synthesize photosScrollView;
@synthesize locationButton;
@synthesize artistTextField;
@synthesize titleTextField;
@synthesize categoryButton;
@synthesize eventButton;
@synthesize descriptionTextView;
@synthesize currentLocation = _currentLocation;

@synthesize art = _art;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        _userAddedImages = [[NSMutableArray alloc] init];
        _imageButtons = [[NSMutableArray alloc] init];
        _newArtDictionary = [[NSMutableDictionary alloc] init];
        
        _addedImageCount = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //setup post button
    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStylePlain target:self action:@selector(postButtonPressed)];
    [self.navigationItem setRightBarButtonItem:postButton];
    
    //add actions
    [self.categoryButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.locationButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.eventButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self setupImages];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [photosScrollView release];
    [locationButton release];
    [artistTextField release];
    [titleTextField release];
    [categoryButton release];
    [eventButton release];
    [descriptionTextView release];
    [descriptionTextView release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setPhotosScrollView:nil];
    [self setLocationButton:nil];
    [self setArtistTextField:nil];
    [self setTitleTextField:nil];
    [self setCategoryButton:nil];
    [self setEventButton:nil];
    [self setDescriptionTextView:nil];
    [self setDescriptionTextView:nil];
    [super viewDidUnload];
}

#pragma mark - Actions
- (void) buttonPressed:(id)sender
{
    if (sender == self.locationButton) {
        [self locationButtonPressed];
    }
    else if (sender == self.categoryButton) {
        [self categoryButtonPressed];
    }
    else if (sender == self.locationButton) {
        [self locationButtonPressed];
    }
}

- (void) categoryButtonPressed
{
    SearchTableViewController *searchTableController = [[SearchTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    NSMutableArray *searchItems = [[NSMutableArray alloc] initWithObjects:
                             [SearchItem searchItemWithTitle:@"Painting" subtitle:@"subtitle1"],
                             [SearchItem searchItemWithTitle:@"Sculpture" subtitle:@"subtitle2"],
                             [SearchItem searchItemWithTitle:@"Mosaic" subtitle:@"subtitle3"],
                             [SearchItem searchItemWithTitle:@"Mural" subtitle:@"subtitle4"],
                             [SearchItem searchItemWithTitle:@"Random" subtitle:@"subtitle5"],
                             [SearchItem searchItemWithTitle:@"Chalk" subtitle:@"subtitle6"],
                             [SearchItem searchItemWithTitle:@"Perfomance" subtitle:@"subtitle7"],
                             [SearchItem searchItemWithTitle:@"Dance" subtitle:@"subtitle8"],
                             nil];
    
    [searchTableController setSearchItems:searchItems];
    [searchTableController setMultiSelectionEnabled:YES];
    [searchTableController setDelegate:self];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
    [searchTableController.navigationItem setLeftBarButtonItem:cancelButton];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchTableController];
    [self presentModalViewController:navController animated:YES];
    
    
}

- (void) locationButtonPressed
{}

- (void) eventButtonPressed
{}

#pragma mark - Art Handlers

- (void) artButtonPressed:(id)sender
{
    EGOImageButton *button = (EGOImageButton*)sender;
    
    PhotoImageView *imgView = [[PhotoImageView alloc] initWithFrame:CGRectOffset(self.view.frame, 0, 0)];
    [imgView setPhotoImageViewDelegate:self];
    [imgView setContentMode:UIViewContentModeScaleAspectFit];
    [imgView setBackgroundColor:kFontColorDarkBrown];
    
    if (button.imageView.image)
        [imgView setImage:button.imageView.image];
    
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view = imgView;
    
    
    [self.navigationController pushViewController:viewController animated:YES];
    DebugLog(@"Button Origin: %f", imgView.photoAttributionButton.frame.origin.y);
    [imgView release];
    [viewController release];
    
    
    
    
}

- (void) photoDeleteButtonPressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    int buttonTag = button.tag;
    
    [_userAddedImages removeObjectAtIndex:(buttonTag - _kUserAddedImageTagBase)];
    
    [self.photosScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self setupImages];
    
    
}

- (void)userAddedImage:(UIImage*)image
{
    //increment the number of new images
    _addedImageCount += 1;
    
    
    [_userAddedImages addObject:image];
    
    //reload the images to show the new image
    [self setupImages];
}

#pragma mark - Image Scroll View
- (void)setupImages
{
	//loop through all the images and add an image view if it doesn't exist yet
	//update the url for each image view that doesn't have one yet
	//this method may be called multiple times as the flickr api returns info on each photo
    //insert the add button at the end of the scroll view
	EGOImageButton *prevView = nil;
	int totalPhotos = _userAddedImages.count;
	int photoCount = 0;
    
    for (UIImage *thisUserImage in _userAddedImages) {
		
		//adjust the image view y offset
		float prevOffset = _kPhotoPadding;
		if (prevView) {
            
			//adjust offset based on the previous frame
			prevOffset = prevView.frame.origin.x + prevView.frame.size.width + _kPhotoSpacing;
			
		} else {
			
			//adjust the initial offset based on the total number of photos
			BOOL isPortrait = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation));
			if (isPortrait) {
				prevOffset = _kPhotoInitialPaddingPortait;
			} else {
				
				switch (totalPhotos) {
					case 1:
						prevOffset = _kPhotoInitialPaddingForOneLandScape;
						break;
						
					case 2:
						prevOffset = _kPhotoInitialPaddingForTwoLandScape;
						break;
						
					case 3:
					default:
						prevOffset = _kPhotoInitialPaddingForThreeLandScape;
						break;
				}
				
			}
            
		}
		
		//grab existing or create new image view
		EGOImageButton *imageView = (EGOImageButton *)[self.photosScrollView viewWithTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
        UIButton *deleteButton = (UIButton*)[imageView viewWithTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
        
		if (!imageView) {
			imageView = [[EGOImageButton alloc] initWithPlaceholderImage:nil];
			[imageView setClipsToBounds:YES];
			[imageView.imageView setContentMode:UIViewContentModeScaleAspectFill];
            [imageView setImage:thisUserImage forState:UIControlStateNormal];
			[imageView setBackgroundColor:[UIColor lightGrayColor]];
			[imageView.layer setBorderColor:[UIColor whiteColor].CGColor];
			[imageView.layer setBorderWidth:6.0f];
            [imageView addTarget:self action:@selector(artButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setFrame:CGRectMake(0, 0, 30.0f, 30.0f)];
            [deleteButton setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.6f]];
            [deleteButton setTitle:@"X" forState:UIControlStateNormal];
            [deleteButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
            [deleteButton addTarget:self action:@selector(photoDeleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [deleteButton setTag:imageView.tag];
            [imageView addSubview:deleteButton];

            
			[self.photosScrollView addSubview:imageView];
            [_imageButtons addObject:imageView];

            
		}
        
        [imageView setFrame:CGRectMake(prevOffset, _kPhotoPadding, _kPhotoWidth, _kPhotoHeight)];
        [imageView setTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
        [deleteButton setTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
		
		
		//adjust the imageView autoresizing masks when there are fewer than 3 images so that they stay centered
		if (imageView && totalPhotos < 3) {
			[imageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
		}
		
		//store the previous view for reference
		//increment photo count
		prevView = imageView;
		photoCount++;
		
	}
	
    //get the add button's offset
    float prevOffset = _kPhotoPadding;
    if (prevView) {
        //adjust offset based on the previous frame
        prevOffset = prevView.frame.origin.x + prevView.frame.size.width + _kPhotoSpacing;
        
    } else {
        
        //adjust the initial offset based on the total number of photos
        BOOL isPortrait = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation));
        if (isPortrait) {
            prevOffset = _kPhotoInitialPaddingPortait;
        } else {
            prevOffset = _kPhotoInitialPaddingForOneLandScape;
        }
    }
    
    //setup the add image button
    UIButton *addImgButton = (UIButton*)[self.photosScrollView viewWithTag:_kAddImageTagBase];
    if (!addImgButton) {
        addImgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [addImgButton setImage:[UIImage imageNamed:@"uploadPhoto_noBg.png"] forState:UIControlStateNormal];
        [addImgButton setTag:_kAddImageTagBase];
        [addImgButton.imageView setContentMode:UIViewContentModeCenter];
        [addImgButton.layer setBorderColor:[UIColor whiteColor].CGColor];
        [addImgButton.layer setBorderWidth:6.0f];
        [addImgButton setBackgroundColor:[UIColor lightGrayColor]];
        [addImgButton addTarget:self action:@selector(addImageButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.photosScrollView addSubview:addImgButton];
    }
    
    [addImgButton setFrame:CGRectMake(prevOffset, _kPhotoPadding, _kPhotoWidth, _kPhotoHeight)];
    
    //adjust the button's autoresizing mask when there are fewer than 3 images so that it stays centered
    if (totalPhotos < 3) {
        [addImgButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    }
    
    
    
	//set the content size
	[self.photosScrollView setContentSize:CGSizeMake(addImgButton.frame.origin.x + addImgButton.frame.size.width + _kPhotoSpacing, self.photosScrollView.frame.size.height)];
	
	
}

#pragma mark - Submission
- (void) postButtonPressed
{
    
    if ([_newArtDictionary objectForKey:@"title"] && [_newArtDictionary objectForKey:@"categories"] && [[_newArtDictionary objectForKey:@"categories"] count] > 0 &&
        _addedImageCount > 0) {
    
        //set the location
        [_newArtDictionary setObject:self.currentLocation forKey:@"location[]"];
        
        //make sure strings are url encoded
        [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"title"]] forKey:@"title"];
        
        if ([_newArtDictionary objectForKey:@"artist"])
            [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"artist"]] forKey:@"artist"];
        
        if ([_newArtDictionary objectForKey:@"description"])
            [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"description"]] forKey:@"description"];
        
#warning TEMPORARILY only grabbing the first category and removing the plural obejct from the dictionary. Waiting on API Update to change. in the future we'll need to urlencode each category
#warning ALSO - setting the key to category as opposed to categories plural
        NSString *firstCat = [[_newArtDictionary objectForKey:@"categories"] objectAtIndex:0];
        [_newArtDictionary setObject:[Utilities urlEncode:firstCat] forKey:@"category"];
        [_newArtDictionary removeObjectForKey:@"categories"];
        
        //call the submit request
        [[AAAPIManager instance] submitArt:_newArtDictionary withTarget:self callback:@selector(artUploadCompleted:) failCallback:@selector(artUploadFailed:)];
        
        
    }
    else {
        UIAlertView *todoAlert = [[UIAlertView alloc] initWithTitle:@"Need More Info" message:@"All art must have a title, category, and photo before submission." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [todoAlert show];
        return;
    }
    
    
}

#pragma mark - Art Upload Callback Methods

- (void)artUploadCompleted:(NSDictionary*)responseDict
{
    //flag to check if this was an edit or a new submission
    BOOL newArt = NO;
    
    if ([responseDict objectForKey:@"success"]) {
        
        //parse new art and update this controller instance's art
        //grab the newly created slug if this is a creation
        if (!_art.slug) {
            [_newArtDictionary setObject:[responseDict objectForKey:@"success"] forKey:@"slug"];
            
            //it was new art
            newArt = YES;
        }
        
        //decode the objects
        for (NSString *thisKey in [_newArtDictionary allKeys]) {
            if ([[_newArtDictionary objectForKey:thisKey] isKindOfClass:[NSString class]])
                [_newArtDictionary setValue:[Utilities urlDecode:[_newArtDictionary objectForKey:thisKey]] forKey:thisKey];
        }
        
        [[AAAPIManager managedObjectContext] lock];
        _art = [[ArtParser artForDict:_newArtDictionary inContext:[AAAPIManager managedObjectContext]] retain];
        [[AAAPIManager managedObjectContext] unlock];
        
        //merge context
        [[AAAPIManager instance] performSelectorOnMainThread:@selector(mergeChanges:) withObject:[NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:[AAAPIManager managedObjectContext]] waitUntilDone:YES];
        [(id)[[UIApplication sharedApplication] delegate] saveContext];
        
    }
    else {
        [self artUploadFailed:responseDict];
        return;
    }
    
    
    //if there are user added images upload them
    for (UIImage *thisImage in _userAddedImages) {
        [[AAAPIManager instance] uploadImage:thisImage forSlug:self.art.slug withFlickrHandle:[Utilities instance].flickrHandle withTarget:self callback:@selector(photoUploadCompleted:) failCallback:@selector(photoUploadFailed:)];
    }

    
}

- (void)artUploadFailed:(NSDictionary*)responseDict
{
    //dismiss loading view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    //show fail alert
    UIAlertView *failedAlertView = [[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"The upload failed. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [failedAlertView show];
    [failedAlertView release];
}

#pragma mark - Photo Upload Callback Methods

- (void)photoUploadCompleted
{
    _addedImageCount -= 1;
    
    //dismiss the alert view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
}

- (void)photoUploadFailed
{
    _addedImageCount -= 1;
    
    //dismiss the alert view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
}


- (void)photoUploadCompleted:(NSDictionary*)responseDict
{
    if ([responseDict objectForKey:@"slug"]) {
        
        //parse the art object returned and update this controller instance's art
        [[AAAPIManager managedObjectContext] lock];
        //_art = [[ArtParser artForDict:responseDict inContext:[AAAPIManager managedObjectContext]] retain];
        [self setArt:[[ArtParser artForDict:responseDict inContext:[AAAPIManager managedObjectContext]] retain]];
        [[AAAPIManager managedObjectContext] unlock];
        
        //merge context
        [[AAAPIManager instance] performSelectorOnMainThread:@selector(mergeChanges:) withObject:[NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:[AAAPIManager managedObjectContext]] waitUntilDone:YES];
    }
    else {
        [self photoUploadFailed:responseDict];
        return;
    }
    
    _addedImageCount -= 1;
    
    //if there are no more photo upload requests processing
    //switch out of edit mode
    if (_addedImageCount == 0) {
        
        //dismiss the alert view
        [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
        
        //reload the map view so the updated/new art is there
        ArtAroundAppDelegate *appDelegate = (id)[[UIApplication sharedApplication] delegate];
        [appDelegate saveContext];
        [appDelegate.mapViewController updateArt];
        
        //clear the user added images array
        [_userAddedImages removeAllObjects];
    }
    
    
}

- (void)photoUploadFailed:(NSDictionary*)responseDict
{
    _addedImageCount -= 1;
    
    //dismiss the alert view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    
}

#pragma mark - Helpers

- (void)showLoadingView:(NSString*)msg
{
    //display loading alert view
    if (!_loadingAlertView) {
        _loadingAlertView = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.tag = 10;
        // Adjust the indicator so it is up a few pixels from the bottom of the alert
        indicator.center = CGPointMake(_loadingAlertView.bounds.size.width / 2, _loadingAlertView.bounds.size.height - 50);
        indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [indicator startAnimating];
        [_loadingAlertView addSubview:indicator];
        [indicator release];
    }
    
    [_loadingAlertView setTitle:msg];
    [_loadingAlertView show];
    
    
    
    //display an activity indicator view in the center of alert
    UIActivityIndicatorView *activityView = (UIActivityIndicatorView*)[_loadingAlertView viewWithTag:10];
    [activityView setCenter:CGPointMake(_loadingAlertView.bounds.size.width / 2, _loadingAlertView.bounds.size.height - 44)];
    [activityView setFrame:CGRectMake(roundf(activityView.frame.origin.x), roundf(activityView.frame.origin.y), activityView.frame.size.width, activityView.frame.size.height)];
}

- (BOOL)findAndResignFirstResponder
{
    if (self.isFirstResponder) {
        [self resignFirstResponder];
        return YES;
    }
    
    if (self.titleTextField.isFirstResponder) {
        [self.titleTextField resignFirstResponder];
        return YES;
    }
    else if (self.artistTextField.isFirstResponder) {
        [self.artistTextField resignFirstResponder];
        return YES;
    }
    else if (self.descriptionTextView.isFirstResponder) {
        [self.descriptionTextView resignFirstResponder];
        return YES;
    }
    
    return NO;
}

#pragma mark - Text View Delegate

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString* newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    [_newArtDictionary setObject:newText forKey:@"description"];
    
    
    return YES;
}
- (void) textViewDidChange:(UITextView *)textView
{

}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    self.navigationItem.rightBarButtonItem.enabled = YES;
    return YES;
}

- (void) textViewDidBeginEditing:(UITextView *)textView {}

- (BOOL) textViewShouldEndEditing:(UITextView *)textView
{
    return YES;
}

- (void) textViewDidEndEditing:(UITextView *)textView
{

}

#pragma mark - Text Field Delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self findAndResignFirstResponder];
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [_newArtDictionary setObject:textField.text forKey:(textField == self.artistTextField) ? @"artist" : @"title"];
}

#pragma mark - PhotoImageViewDelegate
- (void) attributionButtonPressed:(id)sender withTitle:(NSString*)title andURL:(NSURL*)url
{
    //create request
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    //create webview
    UIWebView *webView = [[UIWebView alloc] init];
    [webView loadRequest:request];
    
    //create view controller
    UIViewController *containerViewController = [[UIViewController alloc] init];
    [containerViewController setView:webView];
    [containerViewController setTitle:title];
    
    //create the navcontroller
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:containerViewController];
    
    //create close button and add to nav bar
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(closeModalViewController:)];
    [containerViewController.navigationItem setLeftBarButtonItem:closeButton];
    
    
    //present nav controller
    [self presentModalViewController:navController animated:YES];
    
    
}


#pragma mark - AddImageButton
- (void)addImageButtonTapped
{
    
    UIActionSheet *imgSheet = [[UIActionSheet alloc] initWithTitle:@"Upload Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take a Photo", @"Camera roll", nil];
    [imgSheet setTag:_kAddImageActionSheet];
    [imgSheet showInView:self.view];
    [imgSheet release];
    
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{

    //decide what the picker's source is
    switch (buttonIndex) {
            
        case 0:
        {
            UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
            imgPicker.delegate = self;
            imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentModalViewController:imgPicker animated:YES];
            break;
        }
        case 1:
        {
            UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
            imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imgPicker.delegate = self;
            [self presentModalViewController:imgPicker animated:YES];
            break;
        }
        default:
            break;
    }


}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //dismiss the picker view
    [self dismissViewControllerAnimated:YES completion:^{
        
        
        
        // Get the image from the result
        UIImage* image = [[info valueForKey:@"UIImagePickerControllerOriginalImage"] retain];
        
        //if the user has already been asked for a flickr handle just add image
        if ([Utilities instance].lastFlickrUpdate) {
            
            //add image to user added images array
            [_userAddedImages addObject:image];
            
            [self userAddedImage:image];
            
        }
        else {  //if this is the first upload then prompt for their flickr handle
            
            FlickrNameViewController *flickrNameController = [[FlickrNameViewController alloc] initWithNibName:@"FlickrNameViewController" bundle:[NSBundle mainBundle]];
            [flickrNameController setImage:image];
            flickrNameController.view.autoresizingMask = UIViewAutoresizingNone;
            flickrNameController.delegate = self;
            
            [self.view addSubview:flickrNameController.view];
            [self.navigationItem.backBarButtonItem setEnabled:NO];
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
            
        }
        
    }];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [self dismissViewControllerAnimated:YES completion:^{
        
        
        
        //if the user has already been asked for a flickr handle just add image
        if ([Utilities instance].lastFlickrUpdate) {
            
            //add image to user added images array
            [_userAddedImages addObject:image];
            
            [self userAddedImage:image];
            
        }
        else {  //if this is the first upload then prompt for their flickr handle
            
            FlickrNameViewController *flickrNameController = [[FlickrNameViewController alloc] initWithNibName:@"FlagViewController" bundle:[NSBundle mainBundle]];
            [flickrNameController setImage:image];
            flickrNameController.view.autoresizingMask = UIViewAutoresizingNone;
            flickrNameController.delegate = self;
            
            [self.view addSubview:flickrNameController.view];
            [self.navigationItem.backBarButtonItem setEnabled:NO];   
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
            
        }
        
    }];
}


#pragma mark - FlickrNameViewControllerDelegate
//submit flag
- (void)flickrNameViewControllerPressedSubmit:(id)controller
{
    [Utilities instance].flickrHandle = [[NSString alloc] initWithString:[[(FlickrNameViewController*)controller flickrHandleField] text]];
    [self userAddedImage:[(FlickrNameViewController*)controller image]];
    
    
    
    [[controller view] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    
    
}

//dismiss flag controller
- (void) flickrNameViewControllerPressedCancel:(id)controller
{
    
    [self userAddedImage:[(FlickrNameViewController*)controller image]];
    
    //[[self.view.subviews objectAtIndex:(self.view.subviews.count - 1)] removeFromSuperview];
    [[(FlickrNameViewController*)controller view] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    

}

//successful submission
- (void) flickrNameSubmissionCompleted
{
    [[self.view.subviews objectAtIndex:(self.view.subviews.count - 1)] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    

}

//unsuccessful submission
- (void) flickrNameSubmissionFailed
{
    [[self.view.subviews objectAtIndex:(self.view.subviews.count - 1)] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    

}

#pragma mark - Search Table Delegate
- (void) searchTableViewController:(SearchTableViewController *)searchController didFinishWithSelectedItems:(NSArray *)items
{
 
    //add the cateogries to the new art
    
    //if cats don't exist create the array and add to newArtDict
    if (![_newArtDictionary objectForKey:@"categories"]) {
        NSMutableArray *categories = [[NSMutableArray alloc] init];
        [_newArtDictionary setObject:categories forKey:@"categories"];
        
    }
    
    for (SearchItem *thisItem in items) {
        if (![[_newArtDictionary objectForKey:@"categories"] containsObject:thisItem.title]) {
            [[_newArtDictionary objectForKey:@"categories"] addObject:thisItem.title];
        }
    }
    
    [self dismissModalViewControllerAnimated:YES];
    
}


@end
