import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/my/presentation/bloc/my_bloc.dart';
import '../../domain/enums/calendar_enums.dart';

class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  State<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState
    extends BaseScaffoldPageState<CalendarSettingsPage, MyBloc, MyState> {
  _CalendarSettingsPageState()
      : super(
            backgroundColor: Palette.white,
            horizontalMargin: 0,
            verticalMargin: 0);

  @override
  void initState() {
    super.initState();
    bloc.add(const MyEvent.initialized());
  }

  @override
  String get appBarTitle => context.l10n.settings_calendar_title;

  @override
  Widget buildPage(BuildContext context, MyState state) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.all(20),
            child: Text(l10n.settings_calendar_weekday_language,
                style: context.h6_700Style)),
        _buildOption(context,
            title: l10n.settings_calendar_weekday_korean_first,
            isSelected: state.weekdayLanguage == WeekdayLanguage.ko,
            onTap: () => bloc.add(const MyEvent.calendarSettingsChanged(
                weekdayLanguage: WeekdayLanguage.ko))),
        _buildOption(context,
            title: l10n.settings_calendar_weekday_japanese_first,
            isSelected: state.weekdayLanguage == WeekdayLanguage.ja,
            onTap: () => bloc.add(const MyEvent.calendarSettingsChanged(
                weekdayLanguage: WeekdayLanguage.ja))),
        _buildOption(context,
            title: l10n.settings_calendar_weekday_english_first,
            isSelected: state.weekdayLanguage == WeekdayLanguage.en,
            onTap: () => bloc.add(const MyEvent.calendarSettingsChanged(
                weekdayLanguage: WeekdayLanguage.en))),
        const SizedBox(height: 20),
        Padding(
            padding: const EdgeInsets.all(20),
            child: Text(l10n.settings_calendar_starting_day,
                style: context.h6_700Style)),
        _buildOption(context,
            title: l10n.settings_calendar_starting_day_sunday,
            isSelected: state.startingDay == CalendarStartingDay.sunday,
            onTap: () => bloc.add(const MyEvent.calendarSettingsChanged(
                startingDay: CalendarStartingDay.sunday))),
        _buildOption(context,
            title: l10n.settings_calendar_starting_day_monday,
            isSelected: state.startingDay == CalendarStartingDay.monday,
            onTap: () => bloc.add(const MyEvent.calendarSettingsChanged(
                startingDay: CalendarStartingDay.monday))),
      ],
    );
  }

  Widget _buildOption(BuildContext context,
      {required String title,
      required bool isSelected,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(title, style: context.h6_400Style)),
            if (isSelected)
              Icon(Icons.check, color: context.palette.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
