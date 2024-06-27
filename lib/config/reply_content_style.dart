import 'package:flutter/material.dart';

class ReplyContentStyle {
  static const double fontSizeDisplayName = 17.0 * 0.76;
  static const double fontSizeDisplayContent = 17.0 * 0.88;
  static const double replyContentSize = fontSizeDisplayContent * 2;

  static const EdgeInsets replyParentContainerPadding = EdgeInsets.only(
    left: 4,
    right: 8.0,
    top: 8.0,
    bottom: 8.0,
  );

  static BoxDecoration replyParentContainerDecoration(
    BuildContext context,
    bool ownMessage,
  ) {
    return BoxDecoration(
      color: ownMessage ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static const double prefixBarWidth = 3.0;
  static const double prefixBarVerticalPadding = 4.0;
  static BoxDecoration prefixBarDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      color: Theme.of(context).colorScheme.primary,
    );
  }

  static const double contentSpacing = 6.0;
  static const BorderRadius previewedImageBorderRadius = BorderRadius.all(Radius.circular(4));
  static const double previewedImagePlaceholderPadding = 4.0;

  static TextStyle? displayNameTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: fontSizeDisplayName,
        );
  }

  static TextStyle? replyBodyTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
          fontSize: fontSizeDisplayContent,
        );
  }
}
