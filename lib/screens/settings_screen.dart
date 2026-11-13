import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/services.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final settings = store.settings;

    return ResponsiveScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                context.tr('settings'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // General Section
                _sectionHeader(context, context.tr('general')),
                GlassCard(
                  cornerRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _textSettingTile(
                        context,
                        title: 'Company Name',
                        value: settings.companyName.isNotEmpty ? settings.companyName : 'Not set',
                        icon: CupertinoIcons.building_2_fill,
                        onTap: () => _editStringDialog(
                          context,
                          'Company Name',
                          settings.companyName,
                          (v) => store.updateSettings(settings.copyWith(companyName: v)),
                        ),
                      ),
                      const Divider(height: 16),
                      _textSettingTile(
                        context,
                        title: 'Operator Name',
                        value: settings.operatorName.isNotEmpty ? settings.operatorName : 'Dispatcher',
                        icon: CupertinoIcons.person_fill,
                        onTap: () => _editStringDialog(
                          context,
                          'Operator Name',
                          settings.operatorName,
                          (v) => store.updateSettings(settings.copyWith(operatorName: v)),
                        ),
                      ),
                      const Divider(height: 16),
                      _textSettingTile(
                        context,
                        title: 'Tracking Code Prefix',
                        value: settings.codePrefix,
                        icon: CupertinoIcons.tag_fill,
                        onTap: () => _editStringDialog(
                          context,
                          'Code Prefix',
                          settings.codePrefix,
                          (v) => store.updateSettings(settings.copyWith(codePrefix: v)),
                        ),
                      ),
                      const Divider(height: 16),
                      _pickerSettingTile(
                        context,
                        title: context.tr('language'),
                        value: settings.language.toUpperCase(),
                        icon: CupertinoIcons.globe,
                        onTap: () => _showLanguagePicker(context, store),
                      ),
                      const Divider(height: 16),
                      _pickerSettingTile(
                        context,
                        title: 'Weight Unit',
                        value: settings.weightUnit.toUpperCase(),
                        icon: CupertinoIcons.gauge,
                        onTap: () {
                          final next = settings.weightUnit == 'kg' ? 'lb' : 'kg';
                          store.updateSettings(settings.copyWith(weightUnit: next));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appearance Section
                _sectionHeader(context, context.tr('appearance')),
                GlassCard(
                  cornerRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _pickerSettingTile(
                        context,
                        title: context.tr('theme'),
                        value: settings.theme.toUpperCase(),
                        icon: CupertinoIcons.moon_circle_fill,
                        onTap: () => _showThemePicker(context, store),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(CupertinoIcons.waveform_path, color: RayoColors.primaryBlue),
                        title: const Text('Haptics Feedback', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        value: settings.haptics,
                        onChanged: (val) => store.updateSettings(settings.copyWith(haptics: val)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Security Section
                _sectionHeader(context, context.tr('security')),
                GlassCard(
                  cornerRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(CupertinoIcons.lock_shield_fill, color: RayoColors.successGreen),
                        title: Text(context.tr('app_lock'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Face ID / Touch ID on app launch', style: TextStyle(fontSize: 12)),
                        value: settings.appLockEnabled,
                        onChanged: (val) async {
                          if (val) {
                            final ok = await RayoServices.authenticateBiometrics('Enable Rayo App Lock');
                            if (ok) {
                              store.updateSettings(settings.copyWith(appLockEnabled: true));
                            }
                          } else {
                            store.updateSettings(settings.copyWith(appLockEnabled: false));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Data & Backup Section
                _sectionHeader(context, context.tr('data_backup')),
                GlassCard(
                  cornerRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _actionTile(
                        title: context.tr('export_backup'),
                        subtitle: 'Encrypted offline .rayobackup JSON file',
                        icon: CupertinoIcons.arrow_up_doc_fill,
                        color: RayoColors.primaryBlue,
                        onTap: () => RayoServices.exportBackup(context, store),
                      ),
                      const Divider(height: 16),
                      _actionTile(
                        title: context.tr('import_backup'),
                        subtitle: 'Restore trucks, parcels, and history',
                        icon: CupertinoIcons.arrow_down_doc_fill,
                        color: RayoColors.indigo,
                        onTap: () => RayoServices.importBackup(context, store),
                      ),
                      const Divider(height: 16),
                      _actionTile(
                        title: context.tr('export_csv'),
                        subtitle: 'Spreadsheet compatible parcels list',
                        icon: CupertinoIcons.table_fill,
                        color: RayoColors.truckCyan,
                        onTap: () => RayoServices.exportCsv(context, store),
                      ),
                      const Divider(height: 16),
                      _actionTile(
                        title: context.tr('erase_all'),
                        subtitle: 'Delete all local parcels and trucks',
                        icon: CupertinoIcons.trash_fill,
                        color: RayoColors.dangerRed,
                        onTap: () => _confirmEraseAll(context, store),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Legal & Privacy Policy
                GlassCard(
                  cornerRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: _actionTile(
                    title: context.tr('privacy_policy'),
                    subtitle: 'rayostudio.blogspot.com',
                    icon: CupertinoIcons.shield_lefthalf_fill,
                    color: RayoColors.successGreen,
                    onTap: () async {
                      final uri = Uri.parse('https://rayostudio.blogspot.com/p/privacy-policy.html');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _textSettingTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: RayoColors.primaryBlue),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.chevron_forward, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _pickerSettingTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: RayoColors.primaryBlue),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RayoColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: RayoColors.primaryBlue)),
          ),
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.chevron_forward, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_forward, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  void _editStringDialog(BuildContext context, String title, String currentVal, Function(String) onSave) {
    final c = TextEditingController(text: currentVal);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: c),
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              onSave(c.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppStore store) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Choose Language'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              store.updateSettings(store.settings.copyWith(language: 'system'));
              Navigator.pop(ctx);
            },
            child: const Text('System Default'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              store.updateSettings(store.settings.copyWith(language: 'en'));
              Navigator.pop(ctx);
            },
            child: const Text('English (EN)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              store.updateSettings(store.settings.copyWith(language: 'fr'));
              Navigator.pop(ctx);
            },
            child: const Text('Français (FR)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              store.updateSettings(store.settings.copyWith(language: 'ar'));
              Navigator.pop(ctx);
            },
            child: const Text('العربية (AR - RTL)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, AppStore store) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Theme'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              store.updateSettings(store.settings.copyWith(theme: 'system'));
              Navigator.pop(ctx);
            },
            child: const Text('System'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              store.updateSettings(store.settings.copyWith(theme: 'light'));
              Navigator.pop(ctx);
            },
            child: const Text('Liquid Glass Light'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              store.updateSettings(store.settings.copyWith(theme: 'dark'));
              Navigator.pop(ctx);
            },
            child: const Text('Liquid Glass Dark (Deep Mesh)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _confirmEraseAll(BuildContext context, AppStore store) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(context.tr('erase_all')),
        content: Text(context.tr('erase_confirm')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              store.eraseAllData();
              Navigator.pop(ctx);
            },
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }
}
