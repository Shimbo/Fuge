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
#define TEXT_MAX_MEETUP_SUBJECT_LENGTH  40

// Max status length
#define TEXT_MAX_STATUS_LENGTH          35

// Person cell bg color for matching
#define MATCHING_COLOR_RANK_MAX     30.0f
#define MATCHING_COLOR_BRIGHTNESS   1.0f    // Increase to make bg brighter
#define MATCHING_COLOR_COMPONENT_R  59.0f
#define MATCHING_COLOR_COMPONENT_G  86.0f
#define MATCHING_COLOR_COMPONENT_B  144.0f

//#define MATCHING_COLOR_FB_FRIEND    @"ddd7eb"

// Unread messages color
#define INBOX_UNREAD_CELL_BG_COLOR  @"d7dfeb"

typedef enum kPinColor{
    PinGray = 1,
    PinBlue,
    PinOrange
}PinColor;

#define MEETUP_ALERT_COLOR_RED      @"d43506"
#define MEETUP_ALERT_COLOR_YELLOW   @"eeb300"
#define MEETUP_ALERT_COLOR_GREEN    @"00ad08"
#define MEETUP_ALERT_COLOR_GREY     @"888888"

#define MINI_AVATAR_SIZE            20
#define MINI_AVATAR_COUNT_CELL      4
#define MINI_AVATAR_COUNT_MEETUP    7