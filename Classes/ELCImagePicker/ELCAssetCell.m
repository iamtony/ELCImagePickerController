//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCConsole.h"
#import "ELCOverlayImageView.h"

@interface ELCAssetCell ()

@property (nonatomic, strong) NSArray *rowAssets;
@property (nonatomic, strong) NSMutableArray *imageViewArray;
@property (nonatomic, strong) NSMutableArray *overlayViewArray;

@end

@implementation ELCAssetCell

//Using auto synthesizers

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tapRecognizer];
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;
	}
	return self;
}

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
	for (UIImageView *view in _imageViewArray) {
        [view removeFromSuperview];
	}
    for (ELCOverlayImageView *view in _overlayViewArray) {
        [view removeFromSuperview];
	}
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
    UIImage *overlayImage = nil;
    for (int i = 0; i < [_rowAssets count]; ++i) {

        ELCAsset *asset = [_rowAssets objectAtIndex:i];

        if (i < [_imageViewArray count]) {
            UIImageView *imageView = [_imageViewArray objectAtIndex:i];
            imageView.image = [UIImage imageWithCGImage:asset.asset.thumbnail];
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:asset.asset.thumbnail]];
            [_imageViewArray addObject:imageView];
        }
        
        if (i < [_overlayViewArray count]) {
            ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = asset.selected ? NO : YES;
            overlayView.labIndex.text = [NSString stringWithFormat:@"%d", asset.index + 1];
        } else {
            if (overlayImage == nil) {
                overlayImage = [UIImage imageNamed:@"Overlay.png"];
                // Allow for resizing of the image but keep the "check mark" from resizing
                overlayImage = [overlayImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 60, 60)];
            }
            ELCOverlayImageView *overlayView = [[ELCOverlayImageView alloc] initWithImage:overlayImage];
            [_overlayViewArray addObject:overlayView];
            overlayView.hidden = asset.selected ? NO : YES;
            overlayView.labIndex.text = [NSString stringWithFormat:@"%d", asset.index + 1];
        }
    }
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];

    CGFloat assetWidth = [self widthForAsset];
    CGRect frame = CGRectMake(0, 1, assetWidth, assetWidth);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            asset.selected = !asset.selected;
            ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = !asset.selected;
            if (asset.selected) {
                asset.index = [[ELCConsole mainConsole] numOfSelectedElements];
                [overlayView setIndex:asset.index+1];
                [[ELCConsole mainConsole] addIndex:asset.index];
            }
            else
            {
                int lastElement = [[ELCConsole mainConsole] numOfSelectedElements] - 1;
                [[ELCConsole mainConsole] removeIndex:lastElement];
            }
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + 1;
    }
}

- (void)layoutSubviews
{
    CGFloat assetWidth = [self widthForAsset];
	CGRect frame = CGRectMake(0, 1, assetWidth, assetWidth);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
		[imageView setFrame:frame];
		[self addSubview:imageView];
        
        ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self addSubview:overlayView];
		
        ELCAsset *asset = [_rowAssets objectAtIndex:i];
        NSString *assetType = [asset.asset valueForProperty:ALAssetPropertyType];
        if ([assetType isEqualToString:ALAssetTypeVideo]) {
            UIImage *movieIndicatorImage = [UIImage imageNamed:@"video-file"];
            UIImageView *movieIndicator = [[UIImageView alloc] initWithImage:movieIndicatorImage];
            movieIndicator.frame = CGRectMake(frame.origin.x,
                                              frame.origin.y + frame.size.height - movieIndicatorImage.size.height,
                                              frame.size.width,
                                              movieIndicatorImage.size.height);
            [self insertSubview:movieIndicator belowSubview:overlayView];
            
            NSNumber *duration = [asset.asset valueForProperty:ALAssetPropertyDuration];
            int secs = [duration intValue] % 60;
            int mins = [duration intValue] / 60;
            
            UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
            durationLabel.textColor = [UIColor whiteColor];
            durationLabel.backgroundColor = [UIColor clearColor];
            durationLabel.text = [NSString stringWithFormat:@"%d:%02d", mins, secs];
            durationLabel.font = [UIFont systemFontOfSize:12.0f];
            [durationLabel sizeToFit];
            CGRect durationFrame = durationLabel.frame;
            durationLabel.frame = CGRectMake(frame.origin.x + frame.size.width - durationFrame.size.width - 2,
                                             frame.size.height - durationFrame.size.height - 2,
                                             durationFrame.size.width,
                                             durationFrame.size.height);
            [self insertSubview:durationLabel aboveSubview:movieIndicator];
        }
        
		frame.origin.x = frame.origin.x + frame.size.width + 1;
	}
}

// Obtain the maximum width of an asset so that we show 4 assets per row with 1px separators into consideration
- (CGFloat)widthForAsset
{
    // Number of columns to show
    NSUInteger columns = 4;
    
    CGFloat totalScreenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat assetWidth = (totalScreenWidth - (columns - 1)) / columns;
    return assetWidth;
}


@end
