//
//  FirstViewController.m
//  CurveShow
//
//  Created by  ZhengYiwei on 16/3/28.
//  Copyright © 2016年  ZhengYiwei. All rights reserved.
//

#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%d\t%s\n", __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif

#import "FirstViewController.h"

#define SQUARE_SIZE 0.6                 //主方块宽，不大于等于1

#define UNIT_NUM  10                    //主方块一列几个小方块
#define UNIT_STRONG_NUM 10               //每几行加粗一次，0表示不加粗，若加粗，从坐标轴开始
#define UNIT_STRONG_SIZE 2              //加多粗

#define CTROL_VIEW_SIZE 35              //controlView的宽
#define FONT_SIZE       12              //x，y坐标打印的字符大小

#define KEYBOARD_OFFSET 235
#define SCREEN_HEIGHT 667

@interface FirstViewController (){
    
    CGFloat _width;                       //屏幕的宽
    CGFloat _squareWidth;                //主方块实际的宽
    CGPoint _origin;                    //原点坐标
    
    CGPoint _center;                    //中点坐标
    
    CGFloat _unitWidth;                  //单位方块的宽
    
    CGPoint _start;                     //curve的4个节点，使用虚拟坐标
    CGPoint _end;
    CGPoint _point1;
    CGPoint _point2;
    CGFloat _virtualSquareWidth;                //大方块的宽所代表的坐标系长度
    
    BOOL _isKeyBoardExist;
    
    int _sliderControlPointIndex;       //滑块目前控制的节点是哪个（1，2，3，4）
}

@property UIView *showView;              //显示一切的窗口

@property CAShapeLayer *coordinateLayer;     //用来渲染坐标的图层
@property CAShapeLayer *pathLayer;           //path绘图图层
@property CAShapeLayer *point1Layer;         //控制节点1显示图层
@property CAShapeLayer *point2Layer;
@property CAShapeLayer *indicatorLayer;  //移动节点，显示坐标投影的图层

@property UIView *startControlView;      //各个节点的controlView
@property UIView *endControlView;
@property UIView *point1ControlView;
@property UIView *point2ControlView;


@end

@implementation FirstViewController


-(void) loadView{
    [super loadView];
    
    [self basicInit];
    [self initBasicLayer];
    [self drawCoordinateLayer];
    
    [self refreshRelateLayer];
}




//视图操作组------------------------------------------------------------------------------
//n个textFiled
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{return YES;}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
    }
    return YES;
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    NSString *ID = textField.restorationIdentifier;
    NSLog(@"被修改的参数为：%@",ID);
    
    if ([textField.text isEqualToString:@""]) {
        textField.text = [NSString stringWithFormat:@"0.0"];
    }

    if ([ID isEqualToString:@"fromX"] || [ID isEqualToString:@"fromY"] ||[ID isEqualToString:@"toX"] ||[ID isEqualToString:@"toY"] ) {
        NSLog(@"滑块调整，不做视图重置");
    }else{
        [self setAllUserDataToLocal];
        [self refreshRelateLayer];
    }
    
    return YES;
}
- (void) setAllUserDataToLocal{
    _virtualSquareWidth = [self.rate.text floatValue];
    _start = CGPointMake([self.startX.text floatValue], [self.startY.text floatValue]);
    _end = CGPointMake([self.endX.text floatValue], [self.endY.text floatValue]);
    _point1 = CGPointMake([self.point1X.text floatValue], [self.point1Y.text floatValue]);
    _point2 = CGPointMake([self.point2X.text floatValue], [self.point2Y.text floatValue]);
}
- (void) setLocalToAllUserData{
    self.rate.text = [NSString stringWithFormat:@"%0.1f",_virtualSquareWidth];
    self.startX.text = [NSString stringWithFormat:@"%0.1f",_start.x];
    self.startY.text = [NSString stringWithFormat:@"%0.1f",_start.y];
    self.endX.text = [NSString stringWithFormat:@"%0.1f",_end.x];
    self.endY.text = [NSString stringWithFormat:@"%0.1f",_end.y];
    self.point1X.text = [NSString stringWithFormat:@"%0.1f",_point1.x];
    self.point1Y.text = [NSString stringWithFormat:@"%0.1f",_point1.y];
    self.point2X.text = [NSString stringWithFormat:@"%0.1f",_point2.x];
    self.point2Y.text = [NSString stringWithFormat:@"%0.1f",_point2.y];
}
//两个按钮
- (IBAction)resetAction:(id)sender {
    [self setAllUserDataToLocal];
    [self refreshRelateLayer];
}
- (IBAction)recordAction:(id)sender {
    [self setLocalToAllUserData];
}
//一个滑块和它的textField
-(void) setMovingPointPositionToSlider: (CGPoint)actualPoint{
    CGPoint virtualPoint = [self transActualPointToVirtual:actualPoint];
    
    self.fromX.text = [NSString stringWithFormat:@"%0.1f",virtualPoint.x];
    self.fromY.text = [NSString stringWithFormat:@"%0.1f",virtualPoint.y];
    
    self.sliderForValue.value = 0.0;
}
- (IBAction)sliderChangeAction:(id)sender {
    CGFloat originX = [self.fromX.text floatValue];
    CGFloat originY = [self.fromY.text floatValue];
    CGFloat targetX = [self.toX.text floatValue];
    CGFloat targetY = [self.toY.text floatValue];
    CGFloat value = self.sliderForValue.value;
    
    CGPoint virtualPoint = CGPointMake( originX + (targetX - originX)*value, originY + (targetY - originY)*value );
    switch (_sliderControlPointIndex) {
        case 1:
            _start = virtualPoint;
            break;
        case 2:
            _end = virtualPoint;
            break;
        case 3:
            _point1 = virtualPoint;
            break;
        case 4:
            _point2 = virtualPoint;
            break;
        default:
            break;
    }
    
    [self refreshRelateLayer];
}






//工具方法组------------------------------------------------------------------------------
-(CGPoint) transVirtualPointToActual:(CGPoint)virtualPoint{
    CGFloat scalling = _squareWidth / _virtualSquareWidth;
    return CGPointMake(_origin.x + virtualPoint.x * scalling,_origin.y + virtualPoint.y * scalling);
}
-(CGPoint) transActualPointToVirtual:(CGPoint)actualPoint{
    CGFloat scalling = _virtualSquareWidth / _squareWidth;
    return CGPointMake((actualPoint.x - _origin.x) * scalling,(actualPoint.y - _origin.y) * scalling);
}
-(void) refreshRelateLayer{
    [self drawPathLayer];
    [self drawPoint1Layer];
    [self drawPoint2Layer];
    [self changeControlViewPosition:self.startControlView toPosition:[self transVirtualPointToActual:_start]];
    [self changeControlViewPosition:self.endControlView toPosition:[self transVirtualPointToActual:_end]];
    [self changeControlViewPosition:self.point1ControlView toPosition:[self transVirtualPointToActual:_point1]];
    [self changeControlViewPosition:self.point2ControlView toPosition:[self transVirtualPointToActual:_point2]];
}

//5个图层的绘图组------------------------------------------------------------------------------

-(void) drawPathLayer{
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    
    [bezierPath moveToPoint:[self transVirtualPointToActual:_start]];
    
    [bezierPath addCurveToPoint:[self transVirtualPointToActual:_end] controlPoint1:[self transVirtualPointToActual:_point1] controlPoint2:[self transVirtualPointToActual:_point2]];
    
    [bezierPath moveToPoint:[self transVirtualPointToActual:_end]];
    [bezierPath closePath];
    
    [self.pathLayer setPath:bezierPath.CGPath];
}


-(void) drawPoint1Layer{
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    
    [bezierPath moveToPoint:[self transVirtualPointToActual:_start]];
    [bezierPath addLineToPoint:[self transVirtualPointToActual:_point1]];
    
    CGPoint virtualCenter = CGPointMake((_start.x + _end.x)/2, (_start.y + _end.y)/2);
    [bezierPath addLineToPoint:[self transVirtualPointToActual:virtualCenter]];
    
    [bezierPath moveToPoint:[self transVirtualPointToActual:virtualCenter]];
    [bezierPath closePath];
    
    [self.point1Layer setPath:bezierPath.CGPath];
}


-(void) drawPoint2Layer{
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    
    [bezierPath moveToPoint:[self transVirtualPointToActual:_end]];
    [bezierPath addLineToPoint:[self transVirtualPointToActual:_point2]];
    
    CGPoint virtualCenter = CGPointMake((_start.x + _end.x)/2, (_start.y + _end.y)/2);
    [bezierPath addLineToPoint:[self transVirtualPointToActual:virtualCenter]];
    
    [bezierPath moveToPoint:[self transVirtualPointToActual:virtualCenter]];
    [bezierPath closePath];
    
    [self.point2Layer setPath:bezierPath.CGPath];
}


-(void)drawIndicatorLayer: (CGPoint)indecatedActualPoint{
    //先绘制Y轴指向线（平行x轴）
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    
    CGPoint pointY = CGPointMake(_origin.x, indecatedActualPoint.y);
    CGPoint pointX = CGPointMake(indecatedActualPoint.x, _origin.x);
    
    [bezierPath moveToPoint:pointY];
    [bezierPath addLineToPoint:indecatedActualPoint];
    
    [bezierPath moveToPoint:pointX];
    [bezierPath addLineToPoint:indecatedActualPoint];
    
    [bezierPath closePath];
    
    [self.indicatorLayer setPath:bezierPath.CGPath];

    //去除旧textLayer，加入新layer
    if ([self.indicatorLayer.sublayers count] > 0) {
        self.indicatorLayer.sublayers = nil;
    }
    
    CGPoint virtual_pointY = [self transActualPointToVirtual:pointY];
    CGPoint virtual_pointX = [self transActualPointToVirtual:pointX];
    
    CATextLayer *label_pointY = [[CATextLayer alloc] init];
    label_pointY.bounds = CGRectMake(0, 0, FONT_SIZE * 3.6, FONT_SIZE * 2 + 3);
    [label_pointY setAlignmentMode:kCAAlignmentRight];
    [label_pointY setForegroundColor:[[UIColor grayColor] CGColor]];
    [label_pointY setFontSize:FONT_SIZE];
    
    label_pointY.position = CGPointMake(_origin.x, indecatedActualPoint.y);
    NSString *pointInfo_Y = [NSString stringWithFormat:@"%0.1f:X\n%0.1f:Y",virtual_pointY.x,virtual_pointY.y];
    [label_pointY setString:pointInfo_Y];
    [self.indicatorLayer addSublayer:label_pointY];
    
    
    CATextLayer *label_pointX = [[CATextLayer alloc] init];
    label_pointX.bounds = CGRectMake(0, 0, FONT_SIZE * 3.6, FONT_SIZE * 2 + 3);
    [label_pointX setAlignmentMode:kCAAlignmentRight];
    [label_pointX setForegroundColor:[[UIColor grayColor] CGColor]];
    [label_pointX setFontSize:FONT_SIZE];
    
    label_pointX.position = CGPointMake(indecatedActualPoint.x,_origin.y);
    NSString *pointInfo_X = [NSString stringWithFormat:@"%0.1f:X\n%0.1f:Y",virtual_pointX.x,virtual_pointX.y];
    [label_pointX setString:pointInfo_X];
    [self.indicatorLayer addSublayer:label_pointX];
    
}
-(void) eraseIndicatorLayer{
    self.indicatorLayer.path = nil;
    self.indicatorLayer.sublayers = nil;
}


-(UIView *) initcontrolView: (SEL)handler{
    CGRect rect = CGRectMake(0,0,CTROL_VIEW_SIZE,CTROL_VIEW_SIZE);
    UIView *controlView = [[UIView alloc ]initWithFrame:rect];
    
    
    CAShapeLayer *roundLayer = [[CAShapeLayer alloc]init];
    roundLayer.frame = rect;
    roundLayer.fillColor = [UIColor colorWithRed:251/255.0 green:251/255.0 blue:251/255.0 alpha:0.4].CGColor;
    roundLayer.strokeColor = [UIColor colorWithRed:251/255.0 green:251/255.0 blue:251/255.0 alpha:0.4].CGColor;
    CGFloat radius = rect.size.width / 2.f;
    UIBezierPath *path = [UIBezierPath
                          bezierPathWithArcCenter:CGPointMake(radius,radius)    //圆心
                          radius:radius        //半径
                          startAngle:0                //开始角度，从右水平开始
                          endAngle:M_PI * 2         //结束角度
                          clockwise:YES];
    [roundLayer setPath: path.CGPath];
    [controlView.layer addSublayer:roundLayer];
    
    
    CATextLayer *label = [[CATextLayer alloc] init];
    label.bounds = CGRectMake(0, 0, FONT_SIZE * 3.6, FONT_SIZE * 2 + 3);
    [label setAlignmentMode:kCAAlignmentRight];
    [label setForegroundColor:[[UIColor grayColor] CGColor]];
    [label setFontSize:FONT_SIZE];
    label.anchorPoint = CGPointMake(1, 1);
    label.position = CGPointMake(0,0);
    [controlView.layer addSublayer:label];
    
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:handler];
    [controlView addGestureRecognizer:pan];
    
    return controlView;
}
-(void) changeControlViewPosition: (UIView *)controlView toPosition:(CGPoint) actualPoint{
    controlView.center = actualPoint;
    
    CGPoint virtualPoint = [self transActualPointToVirtual:actualPoint];
    CATextLayer *label = (CATextLayer *)controlView.layer.sublayers[1];
    NSString *pointInfo = [NSString stringWithFormat:@"%0.1f:X\n%0.1f:Y",virtualPoint.x,virtualPoint.y];
    [label setString:pointInfo];
}


//节点控制回调组------------------------------------------------------------------------------

-(void)handleChange_start:(UIPanGestureRecognizer *)pan{
    CGPoint location = [pan locationInView:self.showView];

    _start = [self transActualPointToVirtual:location];
    [self refreshRelateLayer];
    
    [self setMovingPointPositionToSlider:location];
    _sliderControlPointIndex = 1;
    
    [self drawIndicatorLayer:location];
    if (pan.state == UIGestureRecognizerStateEnded  ) {
        [self eraseIndicatorLayer];
    }
}
-(void)handleChange_end:(UIPanGestureRecognizer *)pan{
    CGPoint location = [pan locationInView:self.showView];
    
    _end = [self transActualPointToVirtual:location];
    [self refreshRelateLayer];
    
    [self setMovingPointPositionToSlider:location];
    _sliderControlPointIndex = 2;
    
    [self drawIndicatorLayer:location];
    if (pan.state == UIGestureRecognizerStateEnded  ) {
        [self eraseIndicatorLayer];
    }
}
-(void)handleChange_point1:(UIPanGestureRecognizer *)pan{
    CGPoint location = [pan locationInView:self.showView];
    
    _point1 = [self transActualPointToVirtual:location];
    [self refreshRelateLayer];
    
    [self setMovingPointPositionToSlider:location];
    _sliderControlPointIndex = 3;
    
    [self drawIndicatorLayer:location];
    if (pan.state == UIGestureRecognizerStateEnded  ) {
        [self eraseIndicatorLayer];
    }
}
-(void)handleChange_point2:(UIPanGestureRecognizer *)pan{
    CGPoint location = [pan locationInView:self.showView];
    
    _point2 = [self transActualPointToVirtual:location];
    [self refreshRelateLayer];
    
    [self setMovingPointPositionToSlider:location];
    _sliderControlPointIndex = 4;
    
    [self drawIndicatorLayer:location];
    if (pan.state == UIGestureRecognizerStateEnded  ) {
        [self eraseIndicatorLayer];
    }
}




//基本的初始化工作-------------------------------------------------------------------------------------------
-(void) basicInit{
    _width = [UIScreen mainScreen].bounds.size.width;
    _squareWidth = _width * SQUARE_SIZE;
    _origin = CGPointMake((_width - _squareWidth)/2, (_width - _squareWidth)/2);
    
    _center = CGPointMake(_width/2, _width/2) ;
    _unitWidth = _squareWidth / UNIT_NUM;
    
    _isKeyBoardExist = NO;
    
    _sliderControlPointIndex = 1;
    
    [self setAllUserDataToLocal];
    
}
//layer们的初始化工作
-(void) initBasicLayer{
    CGRect rect = CGRectMake(0, 0, _width, _width);
    
    self.showView = [[UIView alloc]initWithFrame:rect];
    [self.view addSubview:self.showView];
    
    self.coordinateLayer = [[CAShapeLayer alloc]init];
    self.coordinateLayer.bounds = rect;
    self.coordinateLayer.position = _center;
    self.coordinateLayer.fillColor = [UIColor clearColor].CGColor;
    self.coordinateLayer.backgroundColor = [UIColor colorWithRed:246/255.0 green:200/255.0 blue:251/255.0 alpha:1.0].CGColor;
    self.coordinateLayer.strokeColor = [UIColor colorWithRed:249/255.0 green:240/255.0 blue:251/255.0 alpha:1.0].CGColor;
    [self.showView.layer addSublayer:self.coordinateLayer];
    
    
    self.pathLayer = [[CAShapeLayer alloc]init];
    self.pathLayer.bounds = rect;
    self.pathLayer.position = _center;
    self.pathLayer.fillColor = [UIColor clearColor].CGColor;
    self.pathLayer.strokeColor = [UIColor blackColor].CGColor;
    [self.showView.layer addSublayer:self.pathLayer];
    
    self.point1Layer = [[CAShapeLayer alloc]init];
    self.point1Layer.bounds = rect;
    self.point1Layer.position = _center;
    self.point1Layer.fillColor = [UIColor clearColor].CGColor;
    self.point1Layer.strokeColor = [UIColor redColor].CGColor;
    [self.showView.layer addSublayer:self.point1Layer];

    
    self.point2Layer = [[CAShapeLayer alloc]init];
    self.point2Layer.bounds = rect;
    self.point2Layer.position = _center;
    self.point2Layer.fillColor = [UIColor clearColor].CGColor;
    self.point2Layer.strokeColor = [UIColor blueColor].CGColor;
    [self.showView.layer addSublayer:self.point2Layer];

    self.indicatorLayer = [[CAShapeLayer alloc]init];
    self.indicatorLayer.bounds = rect;
    self.indicatorLayer.position = _center;
    self.indicatorLayer.fillColor = [UIColor clearColor].CGColor;
    self.indicatorLayer.strokeColor = [UIColor grayColor].CGColor;
    [self.showView.layer addSublayer:self.indicatorLayer];
    
    self.startControlView = [self initcontrolView:@selector(handleChange_start:)];
    [self.showView addSubview:self.startControlView];
    
    self.endControlView = [self initcontrolView:@selector(handleChange_end:)];
    [self.showView addSubview:self.endControlView];
    
    self.point1ControlView = [self initcontrolView:@selector(handleChange_point1:)];
    [self.showView addSubview:self.point1ControlView];
    
    self.point2ControlView = [self initcontrolView:@selector(handleChange_point2:)];
    [self.showView addSubview:self.point2ControlView];
}

//坐标系的基本绘制---------------------------------------------------------------------------------------------------------
-(void) drawCoordinateLayer{
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    
    CGFloat axisOffset = (_width - _squareWidth)/2;
    
    CGFloat forwardOffset = axisOffset;
    CGFloat backwardOffset = axisOffset;
    
    
    while (forwardOffset <= _width) {
        [bezierPath moveToPoint:CGPointMake(0,forwardOffset)];
        [bezierPath addLineToPoint:CGPointMake(_width,forwardOffset)];
        
        [bezierPath moveToPoint:CGPointMake(forwardOffset,0)];
        [bezierPath addLineToPoint:CGPointMake(forwardOffset,_width)];
        
        forwardOffset += _unitWidth;
    }
    while (backwardOffset >= 0) {
        [bezierPath moveToPoint:CGPointMake(0,backwardOffset)];
        [bezierPath addLineToPoint:CGPointMake(_width,backwardOffset)];
        
        [bezierPath moveToPoint:CGPointMake(backwardOffset,0)];
        [bezierPath addLineToPoint:CGPointMake(backwardOffset,_width)];
        
        backwardOffset -= _unitWidth;
    }
    
    [bezierPath closePath];
    [self.coordinateLayer setPath: bezierPath.CGPath];
    
    if (UNIT_STRONG_NUM > 0) {
        if ([self.coordinateLayer.sublayers count] > 0) {
            self.coordinateLayer.sublayers = nil;
        }
        
        CAShapeLayer *strongLayer  = [[CAShapeLayer alloc]init];
        strongLayer.bounds = self.coordinateLayer.bounds;
        strongLayer.position = _center;
        strongLayer.fillColor = [UIColor clearColor].CGColor;
        strongLayer.strokeColor = [UIColor colorWithRed:251/255.0 green:251/255.0 blue:251/255.0 alpha:1.0].CGColor;
        strongLayer.lineWidth = UNIT_STRONG_SIZE;
        
        UIBezierPath *bezierPath_strong = [[UIBezierPath alloc] init];
        
        forwardOffset = axisOffset;
        backwardOffset = axisOffset;
        
        while (forwardOffset <= _width) {
            [bezierPath_strong moveToPoint:CGPointMake(0,forwardOffset)];
            [bezierPath_strong addLineToPoint:CGPointMake(_width,forwardOffset)];
            
            [bezierPath_strong moveToPoint:CGPointMake(forwardOffset,0)];
            [bezierPath_strong addLineToPoint:CGPointMake(forwardOffset,_width)];
            
            forwardOffset += _unitWidth*UNIT_STRONG_NUM;
        }
        while (backwardOffset >= 0) {
            [bezierPath_strong moveToPoint:CGPointMake(0,backwardOffset)];
            [bezierPath_strong addLineToPoint:CGPointMake(_width,backwardOffset)];
            
            [bezierPath_strong moveToPoint:CGPointMake(backwardOffset,0)];
            [bezierPath_strong addLineToPoint:CGPointMake(backwardOffset,_width)];
            
            backwardOffset -= _unitWidth*UNIT_STRONG_NUM;
        }
        
        [bezierPath_strong closePath];
        [strongLayer setPath: bezierPath_strong.CGPath];
        [self.coordinateLayer addSublayer:strongLayer];
        
    }
    
    
}


//键盘这个东西----------------------------------------------------------------------------------------------------------------
-(void) viewDidAppear:(BOOL)animated{
    //注册键盘出现的通知
    [[NSNotificationCenter defaultCenter]       //通知中心对象
     addObserver:self                        //添加被观察者为自己
     selector:@selector(keyboardShow)    //收到通知后向观察者发出的消息
     name:UIKeyboardDidShowNotification      //需要监视的通知
     object:nil];
    //注册键盘隐藏的通知
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(keyboardHide)
     name:UIKeyboardWillHideNotification
     object:nil];
    NSLog(@"……键盘通知注册完毕");
}
-(void) viewDidDisappear:(BOOL)animated{
    //既然注册了，就在disapper方法中解除注册
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    NSLog(@"……键盘通知解除注册完毕");
}
//不知为何，双击home并跳转后，根view会自动回到初始状态，跳回来后，键盘就遮挡界面了
-(void) keyboardShow{
    NSLog(@"键盘didshow通知到达，但是键盘显示状态为：%0.1f",self.view.center.y);
    if (self.view.center.y > SCREEN_HEIGHT/2 - KEYBOARD_OFFSET) {
            [UIView animateWithDuration:0.5 delay:0.2 options:UIViewAnimationOptionCurveEaseOut  animations:^{
                self.view.center = CGPointMake(self.view.center.x, SCREEN_HEIGHT/2 - KEYBOARD_OFFSET);
            } completion:nil];
        _isKeyBoardExist = YES;
    }
}
-(void) keyboardHide{
    NSLog(@"键盘didshow通知到达，但是键盘显示状态为：%0.1f",self.view.center.y);
    if (self.view.center.y < SCREEN_HEIGHT/2) {
        [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.view.center = CGPointMake(self.view.center.x, SCREEN_HEIGHT/2);
        } completion:nil];
        _isKeyBoardExist = NO;
    }
}

@end
