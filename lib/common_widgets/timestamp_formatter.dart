import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inDays == 0) {
    // Today
    return DateFormat('h:mm a').format(dateTime);
  } else if (difference.inDays == 1) {
    // Yesterday
    return "Yesterday";
  } else if (difference.inDays < 7) {
    // Within the last 7 days, show the weekday name
    return DateFormat('EEEE').format(dateTime);
  } else {
    // Older than a week, show full date
    return DateFormat('dd/MM/yy').format(dateTime);
  }
}
