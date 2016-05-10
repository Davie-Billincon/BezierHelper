//
//  FirstViewController.h
//  CurveShow
//
//  Created by  ZhengYiwei on 16/3/28.
//  Copyright © 2016年  ZhengYiwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *rate;
@property (weak, nonatomic) IBOutlet UITextField *startX;
@property (weak, nonatomic) IBOutlet UITextField *startY;
@property (weak, nonatomic) IBOutlet UITextField *endX;
@property (weak, nonatomic) IBOutlet UITextField *endY;
@property (weak, nonatomic) IBOutlet UITextField *point1X;
@property (weak, nonatomic) IBOutlet UITextField *point1Y;
@property (weak, nonatomic) IBOutlet UITextField *point2X;
@property (weak, nonatomic) IBOutlet UITextField *point2Y;
@property (weak, nonatomic) IBOutlet UITextField *fromX;
@property (weak, nonatomic) IBOutlet UITextField *fromY;
@property (weak, nonatomic) IBOutlet UITextField *toX;
@property (weak, nonatomic) IBOutlet UITextField *toY;

- (IBAction)resetAction:(id)sender;
- (IBAction)recordAction:(id)sender;
- (IBAction)sliderChangeAction:(id)sender;
@property (weak, nonatomic) IBOutlet UISlider *sliderForValue;




@end

