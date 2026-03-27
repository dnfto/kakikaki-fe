import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/dialogue/common_dialogue.dart';
import 'package:kakikaki/app/widget/overlay/common_tooltip.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/my/presentation/bloc/my_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BaseScaffoldPageState<MyPage, MyBloc, MyState>
    with WidgetsBindingObserver {
  _MyPageState()
      : super(
            horizontalMargin: 0,
            verticalMargin: 0,
            isBottomNavigationBar: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bloc.add(const MyEvent.initialized());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final status = await Permission.notification.status;
      final isGranted =
          status.isGranted || status.isLimited || status.isProvisional;

      if (bloc.state.isAlarmEnabled != isGranted) {
        bloc.add(MyEvent.alarmToggled(isGranted));
      }
    }
  }

  @override
  String get appBarTitle => context.l10n.my_page_title;

  @override
  Widget buildPage(BuildContext context, MyState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSettingsList(context, state),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, MyState state) {
    final l10n = context.l10n;
    return Column(
      children: [
        _buildSettingItem(context,
            icon: Icons.book_outlined,
            title: l10n.my_page_diary_feed,
            onTap: () => context.push('/my/diaries')),
        _buildSettingItem(context,
            icon: Icons.chat_outlined,
            title: l10n.my_page_inquiry,
            onTap: () => context.push('/my/inquiry')),
        _buildSettingItem(context,
            icon: Icons.language,
            title: l10n.my_page_language_settings,
            onTap: () => context.push('/my/language-settings')),
        _buildSettingItem(context,
            icon: Icons.calendar_today_outlined,
            title: l10n.my_page_calendar_settings,
            onTap: () => context.push('/my/calendar-settings')),
        _buildSettingItem(context,
            icon: Icons.palette_outlined,
            title: l10n.my_page_theme_settings,
            onTap: () => context.push('/my/color-settings')),
        _buildSettingItem(
          context,
          icon: Icons.description_outlined,
          title: l10n.my_page_privacy_policy,
          onTap: () async {
            final uri = Uri.parse(
                'https://liberating-engineer-32d.notion.site/32bcb4f4390180898da7fe857041ab82?source=copy_link');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _buildSettingItem(context,
            icon: Icons.code_outlined,
            title: l10n.my_page_open_source_license,
            onTap: () => context.push('/my/open-source-license')),
        _buildSettingItem(
          context,
          icon: Icons.info_outline,
          title: l10n.my_page_version_info,
          trailing: state.appVersion.isNotEmpty
              ? Text(state.appVersion,
                  style: context.h7_400Style.copyWith(color: Palette.gray50))
              : null,
        ),
        _buildSettingItem(context,
            icon: Icons.person_off_outlined,
            title: l10n.my_page_withdrawal,
            onTap: () => context.push('/my/withdrawal')),
        InkWell(
          onTap: () => _showLogoutDialog(context),
          child: _buildSettingItem(context,
              icon: Icons.logout, title: l10n.my_page_logout),
        ),
        _buildAlarmSettingItem(context, state),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context,
      {required IconData icon,
      required String title,
      Widget? trailing,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Palette.gray90),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: context.h6_400Style)),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            const SizedBox(width: 8),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 20, color: Palette.gray30),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    CommonDialogue.showTwoChoiceDialogue(
      context: context,
      title: context.l10n.my_page_logout,
      content: context.l10n.my_page_logout_confirm,
      onElevatedButtonPressed: () {
        getIt<GlobalBloc>().add(const GlobalEvent.logoutRequested());
      },
    );
  }

  Widget _buildAlarmSettingItem(BuildContext context, MyState state) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_outlined,
              size: 24, color: Palette.gray90),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.my_page_alarm_toggle,
                    style: context.h6_400Style,
                  ),
                ),
                const SizedBox(width: 6),
                CommonTooltip(
                  message: l10n.my_page_alarm_tooltip,
                  direction: TooltipDirection.right,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: state.isAlarmEnabled,
            onChanged: _onAlarmSwitchChanged,
            activeThumbColor: context.palette.primary,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _onAlarmSwitchChanged(bool isEnabled) async {
    var status = await Permission.notification.status;
    final systemGranted =
        status.isGranted || status.isLimited || status.isProvisional;

    if (isEnabled) {
      if (status.isDenied) {
        status = await Permission.notification.request();
      }

      final grantedAfter =
          status.isGranted || status.isLimited || status.isProvisional;
      if (grantedAfter) {
        bloc.add(const MyEvent.alarmToggled(true));
      } else {
        if (!mounted) return;
        final goToSettings = await CommonDialogue.showTwoChoiceConfirmDialogue(
          context: context,
          title: context.l10n.my_page_notification_enable_permission_title,
          content: context.l10n.my_page_notification_enable_permission_content,
          elevatedButtonText:
              context.l10n.my_page_notification_permission_go_to_settings,
          outlineButtonText: context.l10n.action_cancel,
          barrierDismissible: false,
        );
        if (goToSettings == true) {
          await openAppSettings();
        }
      }
    } else {
      if (systemGranted) {
        if (!mounted) return;
        final goToSettings = await CommonDialogue.showTwoChoiceConfirmDialogue(
          context: context,
          title: context.l10n.my_page_notification_disable_title,
          content: context.l10n.my_page_notification_disable_content,
          elevatedButtonText:
              context.l10n.my_page_notification_permission_go_to_settings,
          outlineButtonText: context.l10n.action_cancel,
          barrierDismissible: false,
        );
        if (goToSettings == true) {
          await openAppSettings();
        }
      } else {
        bloc.add(const MyEvent.alarmToggled(false));
      }
    }
  }
}
