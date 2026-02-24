/// Date formatting and parsing utilities
library;

import 'package:intl/intl.dart';

class DateUtils {
  DateUtils._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _apiDateTimeFormat =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM', 'fr_FR');
  static final DateFormat _fullDateFormat =
      DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
  static final DateFormat _relativeTimeFormat = DateFormat('HH:mm');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatApiDate(DateTime date) => _apiDateFormat.format(date);
  static String formatApiDateTime(DateTime date) =>
      _apiDateTimeFormat.format(date.toUtc());
  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);
  static String formatFullDate(DateTime date) => _fullDateFormat.format(date);

  static DateTime parseApiDate(String date) => _apiDateFormat.parse(date);
  static DateTime parseApiDateTime(String dateTime) =>
      _apiDateTimeFormat.parse(dateTime, true).toLocal();

  /// Relative time label (Aujourd'hui, Hier, date)
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui ${_relativeTimeFormat.format(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Hier ${_relativeTimeFormat.format(date)}';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE HH:mm', 'fr_FR').format(date);
    } else {
      return _dateTimeFormat.format(date);
    }
  }

  /// Time ago label (il y a 5 min, 2h, etc.)
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return _dateFormat.format(date);
    }
  }
}
