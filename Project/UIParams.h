//
//  UIParams.h
//  Fuge
//
//  Created by Mikhail Larionov on 7/18/13.
//
//

// Text field for outcoming messages
#define TEXT_MESSAGE_FIELD_MAX_LINES    9

// Meetup subject
#define TEXT_MAX_MEETUP_SUBJECT_LENGTH  27

// Max status length
#define TEXT_MAX_STATUS_LENGTH          35

// Person cell bg color for matching
#define MATCHING_COLOR_RANK_MAX     50.0f
#define MATCHING_COLOR_BRIGHTNESS   1.0f    // Increase to make bg brighter
#define MATCHING_COLOR_COMPONENT_R  75.0f
#define MATCHING_COLOR_COMPONENT_G  108.0f
#define MATCHING_COLOR_COMPONENT_B  162.0f

// Unread messages color
#define INBOX_UNREAD_CELL_BG_COLOR  @"d7dfeb"

typedef enum kPinColor{
    PinGray = 1,
    PinBlue,
    PinOrange
}PinColor;
