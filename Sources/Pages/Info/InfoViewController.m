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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // for fun, don't blame me)
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

@end
