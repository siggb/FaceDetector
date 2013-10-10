//
//  InfoViewController.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 08.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()
{
    BOOL isViewed;
}

@end

@implementation InfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = nil;
    if (isViewed == NO) {
        utterance = [AVSpeechUtterance speechUtteranceWithString:@"Info page"];
        isViewed = YES;
    }
    else {
        utterance = [AVSpeechUtterance speechUtteranceWithString:@"Seriusly, this is Info page!"];
    }
    utterance.rate = AVSpeechUtteranceMinimumSpeechRate;
    [synthesizer speakUtterance:utterance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
