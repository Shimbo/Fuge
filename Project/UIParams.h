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
#define TEXT_MAX_STATUS_LENGTH          40

// Person cell bg color for matching
#define MATCHING_COLOR_RANK_MAX     30.0f
#define MATCHING_COLOR_BRIGHTNESS   1.0f    // Increase to make bg brighter
#define MATCHING_COLOR_COMPONENT_R  59.0f
#define MATCHING_COLOR_COMPONENT_G  86.0f
#define MATCHING_COLOR_COMPONENT_B  144.0f

//#define MATCHING_COLOR_FB_FRIEND    @"ddd7eb"

// Unread messages color
#ifdef TARGET_FUGE

#define INBOX_UNREAD_CELL_BG_COLOR  @"d7dfeb"
#define ACTIVITY_INDICATOR_COLOR    @"ff9416"
#define NAVBAR_BACKGROUND_COLOR     @"ffc100"
#define TABLE_FOOTER_COLOR          @"fcf3d8"
#define TABLE_SEPARATOR_COLOR       @"ff9416"
#define TABLE_SEARCH_COLOR          @"ff9416"
#define TABLE_SELECTION_COLOR       @"ff9416"

#elif defined TARGET_S2C

#define INBOX_UNREAD_CELL_BG_COLOR  @"ffefd0"
#define ACTIVITY_INDICATOR_COLOR    @"ff9416"
#define NAVBAR_BACKGROUND_COLOR     @"ffc100"
#define TABLE_FOOTER_COLOR          @"fcf3d8"
#define TABLE_SEPARATOR_COLOR       @"ff9416"
#define TABLE_SEARCH_COLOR          @"ff9416"
#define TABLE_SELECTION_COLOR       @"ff9416"

#endif

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