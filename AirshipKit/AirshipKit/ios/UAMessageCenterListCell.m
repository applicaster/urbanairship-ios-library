/* Copyright Airship and Contributors */

#import "UAMessageCenterListCell.h"
#import "UAInboxMessage.h"
#import "UAMessageCenterDateUtils.h"
#import "UAMessageCenterStyle.h"

@implementation UAMessageCenterListCell

- (void)setData:(UAInboxMessage *)message {
    self.date.text = [UAMessageCenterDateUtils formattedDateRelativeToNow:message.messageSent];
    self.title.text = message.title;
    self.unreadIndicator.hidden = !message.unread;
}

- (void)setMcstyle:(UAMessageCenterStyle *)mcstyle {
    _mcstyle = mcstyle;

    BOOL hidden = !mcstyle.iconsEnabled;
    self.listIconView.hidden = hidden;

    // if the icon view is hidden, set a zero width constraint to allow related views to fill its space
    if (hidden) {
        UIImageView *iconView = self.listIconView;

        NSArray *zeroWidthConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconView(0)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(iconView)];

        [self.listIconView addConstraints:zeroWidthConstraints];
    }

    self.listIconView.hidden = !mcstyle.iconsEnabled;

    if (mcstyle.cellColor) {
        self.backgroundColor = mcstyle.cellColor;
    }

    if (mcstyle.cellHighlightedColor) {
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = mcstyle.cellHighlightedColor;
        self.selectedBackgroundView = bgColorView;
    }

    if (mcstyle.cellTitleFont) {
        self.title.font = mcstyle.cellTitleFont;
    }

    if (mcstyle.cellTitleColor) {
        self.title.textColor = mcstyle.cellTitleColor;
    }

    if (mcstyle.cellTitleHighlightedColor) {
        self.title.highlightedTextColor = mcstyle.cellTitleHighlightedColor;
    }

    if (mcstyle.cellDateFont) {
        self.date.font = mcstyle.cellDateFont;
    }
    
    if (mcstyle.cellDateColor) {
        self.date.textColor = mcstyle.cellDateColor;
    }

    if (mcstyle.cellDateHighlightedColor) {
        self.date.highlightedTextColor = mcstyle.cellDateHighlightedColor;
    }

    if (mcstyle.cellTintColor) {
        self.tintColor = mcstyle.cellTintColor;
    }

    // Set unread indicator background color if explicitly provided, otherwise try to apply
    // tints lowest-level first, up the view hierarchy
    if (mcstyle.unreadIndicatorColor) {
        self.unreadIndicator.backgroundColor = mcstyle.unreadIndicatorColor;
    } else if (mcstyle.cellTintColor) {
        self.unreadIndicator.backgroundColor = self.mcstyle.cellTintColor;
    } else if (mcstyle.tintColor) {
        self.unreadIndicator.backgroundColor = self.mcstyle.tintColor;
    }
    
    // needed for retina displays because the unreadIndicator is configured to rasterize in
    // UAMessageCenterListCell.xib via user-defined runtime attributes (layer.shouldRasterize)
    self.unreadIndicator.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

// Override to prevent the default implementation from covering up the unread indicator
 - (void)setSelected:(BOOL)selected animated:(BOOL)animated {
     if (selected) {
         UIColor *defaultColor = self.unreadIndicator.backgroundColor;
         [super setSelected:selected animated:animated];
         self.unreadIndicator.backgroundColor = defaultColor;
     } else {
         [super setSelected:selected animated:animated];
     }
}

// Override to prevent the default implementation from covering up the unread indicator
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        UIColor *defaultColor = self.unreadIndicator.backgroundColor;
        [super setHighlighted:highlighted animated:animated];
        self.unreadIndicator.backgroundColor = defaultColor;

    } else {
        [super setHighlighted:highlighted animated:animated];
    }
}

@end
