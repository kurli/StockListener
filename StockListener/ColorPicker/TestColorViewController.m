//
//  TestColorViewController.m
//  RSColorPicker
//
//  Created by Ryan Sullivan on 7/14/13.
//

#import "TestColorViewController.h"
#import "RSBrightnessSlider.h"
#import "RSOpacitySlider.h"

@implementation TestColorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) doneClicked:(id)headsetImg {
    if (self.onFinish != nil) {
        self.onFinish(_colorPicker.selectionColor);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(210, 20, 90, 44)];
    [button setTitle:@"完成" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(doneClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    // View that displays color picker (needs to be square)
    _colorPicker = [[RSColorPickerView alloc] initWithFrame:CGRectMake(20.0, 64.0, 280.0, 280.0)];

    // Optionally set and force the picker to only draw a circle
	//    [_colorPicker setCropToCircle:YES]; // Defaults to NO (you can set BG color)

    // Set the selection color - useful to present when the user had picked a color previously
    [_colorPicker setSelectionColor:self.color];

	//    [_colorPicker setSelectionColor:[UIColor colorWithRed:1 green:0 blue:0.752941 alpha:1.000000]];
	//    [_colorPicker setSelection:CGPointMake(269, 269)];

    // Set the delegate to receive events
    [_colorPicker setDelegate:self];

    [self.view addSubview:_colorPicker];

    // View that shows selected color
    _colorPatch = [[UIView alloc] initWithFrame:CGRectMake(160, 370.0, 150, 30.0)];
    [self.view addSubview:_colorPatch];
    
    // View that controls brightness
    _brightnessSlider = [[RSBrightnessSlider alloc] initWithFrame:CGRectMake(20, 330, 280, 30)];
    [_brightnessSlider setColorPicker:_colorPicker];
    [self.view addSubview:_brightnessSlider];
}

#pragma mark - RSColorPickerView delegate methods

- (void)colorPickerDidChangeSelection:(RSColorPickerView *)cp {

    // Get color data
    UIColor *color = [cp selectionColor];

    CGFloat r, g, b, a;
    [[cp selectionColor] getRed:&r green:&g blue:&b alpha:&a];

    // Update important UI
    _colorPatch.backgroundColor = color;
    _brightnessSlider.value = [cp brightness];
    _opacitySlider.value = [cp opacity];

    // Debug
    NSString *colorDesc = [NSString stringWithFormat:@"rgba: %f, %f, %f, %f", r, g, b, a];
    NSLog(@"%@", colorDesc);
    int ir = r * 255;
    int ig = g * 255;
    int ib = b * 255;
    int ia = a * 255;
    colorDesc = [NSString stringWithFormat:@"rgba: %d, %d, %d, %d", ir, ig, ib, ia];
    NSLog(@"%@", colorDesc);
    _rgbLabel.text = colorDesc;

    NSLog(@"%@", NSStringFromCGPoint(cp.selection));
}

@end
