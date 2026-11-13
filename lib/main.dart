import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'store/app_store.dart';
import 'theme/theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/parcel_list_screen.dart';
import 'screens/truck_list_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStore(),
      child: const RayoTrackingApp(),
    ),
  );
}

class RayoTrackingApp extends StatelessWidget {
  const RayoTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    // Determine Theme Mode
    ThemeMode themeMode = ThemeMode.system;
    if (store.settings.theme == 'light') {
      themeMode = ThemeMode.light;
    } else if (store.settings.theme == 'dark') {
      themeMode = ThemeMode.dark;
    }

    // Determine Locale
    Locale? appLocale;
    if (store.settings.language != 'system') {
      appLocale = Locale(store.settings.language);
    }

    final accentColor = RayoColors.parseHex(store.settings.accentHex);

    return MaterialApp(
      title: 'Rayo Tracking',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      locale: appLocale,
      localizationsDelegates: const [
        RayoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: accentColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
          primary: accentColor,
        ),
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF2F5FB),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: accentColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
          primary: accentColor,
        ),
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFF0B111E),
      ),
      home: const MainGate(),
    );
  }
}

class MainGate extends StatefulWidget {
  const MainGate({super.key});

  @override
  State<MainGate> createState() => _MainGateState();
}

class _MainGateState extends State<MainGate> {
  bool _isUnlocked = false;
  bool _checkedLock = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<AppStore>();
    if (!store.isLoading && !_checkedLock) {
      _checkedLock = true;
      if (store.settings.appLockEnabled) {
        _authenticate();
      } else {
        _isUnlocked = true;
      }
    }
  }

  Future<void> _authenticate() async {
    final ok = await RayoServices.authenticateBiometrics(
      'Unlock Rayo Tracking',
    );
    setState(() {
      _isUnlocked = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    if (store.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Biometrics Lock Screen
    if (store.settings.appLockEnabled && !_isUnlocked) {
      return Scaffold(
        body: RayoBackground(
          child: Center(
            child: GlassCard(
              cornerRadius: 28,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 54,
                    color: RayoColors.primaryBlue,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Rayo Tracking Locked',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Authenticate using Face ID / Passcode'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RayoColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _authenticate,
                    child: const Text('Unlock with Biometrics'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Onboarding
    if (!store.settings.hasOnboarded) {
      return OnboardingScreen(onFinished: () => setState(() {}));
    }

    return const AppHomeScreen();
  }
}

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _currentIndex = 0;

  void _onTabSelect(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isWide = MediaQuery.of(context).size.width > 700;

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelect),
      const ParcelListScreen(),
      const TruckListScreen(),
      const SearchScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: RayoBackground(
        child: Stack(
          children: [
            Row(
              children: [
                // iPad / Landscape Dual-Screen Navigation Rail
                if (isLandscape || isWide)
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.6),
                          border: Border(
                            right: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 36),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: RayoColors.primaryBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                CupertinoIcons.cube_box_fill,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _railItem(
                              0,
                              CupertinoIcons.square_grid_2x2_fill,
                              context.tr('dashboard'),
                            ),
                            _railItem(
                              1,
                              CupertinoIcons.archivebox_fill,
                              context.tr('parcels'),
                            ),
                            _railItem(
                              2,
                              CupertinoIcons.bus,
                              context.tr('trucks'),
                            ),
                            _railItem(
                              3,
                              CupertinoIcons.search,
                              context.tr('search'),
                            ),
                            const Spacer(),
                            _railItem(
                              4,
                              CupertinoIcons.gear_alt_fill,
                              context.tr('settings'),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Main Active Content
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: screens),
                ),
              ],
            ),

            // Authentic Apple Liquid Glass Tab Bar (Portrait)
            if (!isLandscape && !isWide)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF141F32).withValues(alpha: 0.88)
                            : Colors.white.withValues(alpha: 0.88),
                        border: Border(
                          top: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: true,
                        child: SizedBox(
                          height: 52,
                          child: Row(
                            children: [
                              _tabButton(
                                0,
                                CupertinoIcons.square_grid_2x2,
                                CupertinoIcons.square_grid_2x2_fill,
                                context.tr('dashboard'),
                              ),
                              _tabButton(
                                1,
                                CupertinoIcons.archivebox,
                                CupertinoIcons.archivebox_fill,
                                context.tr('parcels'),
                              ),
                              _tabButton(
                                2,
                                CupertinoIcons.bus,
                                CupertinoIcons.bus,
                                context.tr('trucks'),
                              ),
                              _tabButton(
                                3,
                                CupertinoIcons.search,
                                CupertinoIcons.search,
                                context.tr('search'),
                              ),
                              _tabButton(
                                4,
                                CupertinoIcons.gear_alt,
                                CupertinoIcons.gear_alt_fill,
                                context.tr('settings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = RayoColors.primaryBlue;
    final inactiveColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF8E8E93);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _railItem(int index, IconData icon, String tooltip) {
    final isSelected = _currentIndex == index;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? RayoColors.primaryBlue.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isSelected ? RayoColors.primaryBlue : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}
