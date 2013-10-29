//
//  InboxCell.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/11/13.
//
//

#import "InboxCell.h"
#import "MeetupAnnotation.h"
#import "MeetupAnnotationView.h"
#import "GlobalData.h"

@implementation InboxCell

- (void)previewTapped:(id)sender {
    if ( _event )
        if ( _event.strOwnerName )
        {
            // Mark grey if blue
            MeetupAnnotation* tempAnnotation = [[MeetupAnnotation alloc] initWithMeetup:_event];
            if (tempAnnotation.pinColor == PinBlue )
            {
                [_pinImage setPinColor:PinGray withPin:FALSE];
                
                // Mark as read
                [globalData setEventRead:_event.strId withExpirationDate:_event.dateTimeExp];
            }
        }
}

@end
