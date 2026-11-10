import 'show.dart';

/// One show in the weekly schedule of the source.
///
/// The release data lives here and not in [Show], because a [Show] is saved
/// with favorites and history and the release changes every week.
class ScheduleEntry {
  final Show show;

  /// The source marks this week's episode as out.
  final bool released;

  /// When this week's episode comes out (UTC), when the source gives it.
  final DateTime? releaseAt;

  /// The release text as the source writes it, for example "at 12:02". The
  /// time in it is UTC.
  final String? releaseText;

  const ScheduleEntry({
    required this.show,
    this.released = false,
    this.releaseAt,
    this.releaseText,
  });
}
