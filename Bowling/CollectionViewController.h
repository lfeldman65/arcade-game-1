//
//  CollectionViewController.h
//  Bowling
//
//  Created by Maurice on 10/24/16.
//  Copyright © 2016 Larry Feldman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *myCollectionView;
@property (strong, nonatomic) IBOutlet UILabel *tilesRemainingLabel;
@property (strong, nonatomic) IBOutlet UILabel *bestTime;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *levelLabel;

@end