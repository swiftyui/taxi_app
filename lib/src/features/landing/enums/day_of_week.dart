enum DayOfWeek {
  monday(value: 'Mon'),
  tuesday(value: 'Tue'),
  wednesday(value: 'Wed'),
  thursday(value: 'Thu'),
  friday(value: 'Fri'),
  saturday(value: 'Sat'),
  sunday(value: 'Sun');

  const DayOfWeek({required this.value});

  final String value;

  static DayOfWeek fromValue(String value) {
    for (final day in DayOfWeek.values) {
      if (day.value == value) {
        return day;
      }
    }
    throw ArgumentError('Invalid day of week value: $value');
  }
}
