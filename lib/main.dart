import 'pages/landing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/admin.dart';
import 'pages/events.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/manage_notifications.dart';
import 'pages/manage_users.dart';
import 'pages/notifications.dart';
import 'pages/profile.dart';
import 'pages/signup.dart';
import 'pages/timetables.dart';
import 'pages/addEvents.dart';
import 'pages/addClass.dart';
import 'pages/settings.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/theme_provider.dart';
import 'pages/updateClass.dart';
import 'pages/updateEvent.dart';
import 'widgets/notification_provider.dart';
import 'pages/admin_broadcast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ogpaekhtxtbjdvhdrfcs.supabase.co',
    anonKey: 'sb_publishable_yBubs2D-ySAtbQL2QDHoqA_t0vBim70',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

const String loginRoute = '/login';
const String signupRoute = '/signup';
const String homeRoute = '/home';
const String eventsRoute = '/events';
const String landingRoute = '/landing';
const String timetablesRoute = '/timetables';
const String addEventRoute = '/addEvent';
const String addClassRoute = '/addClass';
const String notificationsRoute = '/notifications';
const String manageNotificationsRoute = '/manageNotifications';
const String manageUsersRoute = '/manageUsers';
const String profileRoute = '/profile';
const String adminRoute = '/admin';
const String settingsRoute = '/settings';
const String updateClassRoute = '/updateClass';
const String updateEventRoute = '/updateEvent';
const String adminBroadcastRoute = '/adminBroadcast';

class CampusEventsApp extends StatelessWidget {
  const CampusEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    const amberSmoke = Color(0xFFF2E0D0);
    const blueMirage = Color(0xFF5E88B0);
    const fallbackBlueMirage = Color(0xFF5C6D7C);

    // 🌞 LIGHT THEME
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: blueMirage,
      brightness: Brightness.light,
    ).copyWith(
      primary: blueMirage,
      secondary: fallbackBlueMirage,
      tertiary: amberSmoke,
      surface: Colors.white,
    );

    // 🌙 DARK THEME
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: blueMirage,
      brightness: Brightness.dark,
    ).copyWith(
      primary: blueMirage,
      secondary: fallbackBlueMirage,
      tertiary: amberSmoke,
      surface: const Color(0xFF121212),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Events',

      themeMode: themeProvider.themeMode,

      // ☀️ LIGHT
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: fallbackBlueMirage,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9F6F0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // 🌙 DARK
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
        ),
      ),

      initialRoute: landingRoute,

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case loginRoute:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case signupRoute:
            return MaterialPageRoute(builder: (_) => const SignupPage());
          case homeRoute:
            return MaterialPageRoute(builder: (_) => const HomePage());
          case eventsRoute:
            return MaterialPageRoute(builder: (_) => const EventsPage());
          case landingRoute:
            return MaterialPageRoute(builder: (_) => const LandingPage());
          case timetablesRoute:
            return MaterialPageRoute(builder: (_) => const TimetablesPage());
          case addEventRoute:
            return MaterialPageRoute(builder: (_) => const AddEventPage());
          case updateEventRoute:
            return MaterialPageRoute(builder: (_) => const UpdateEventPage());
          case addClassRoute:
            return MaterialPageRoute(builder: (_) => const AddClassPage());
          case updateClassRoute:
            return MaterialPageRoute(builder: (_) => const UpdateClassPage());
          case notificationsRoute:
            return MaterialPageRoute(builder: (_) => const NotificationsPage());
          case manageNotificationsRoute:
            return MaterialPageRoute(
              builder: (_) => const ManageNotificationsPage(),
            );
          case manageUsersRoute:
            return MaterialPageRoute(builder: (_) => const ManageUsersPage());
          case profileRoute:
            return MaterialPageRoute(builder: (_) => const ProfilePage());
          case adminRoute:
            return MaterialPageRoute(builder: (_) => const AdminPage());
          case settingsRoute:
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case adminBroadcastRoute:
            return MaterialPageRoute(builder: (_) => const AdminBroadcastPage());
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}

// ✅ MyApp now listens to auth state and starts/stops the notification stream
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;

    _authStream.listen((data) {
      final notifProvider = context.read<NotificationProvider>();

      if (data.event == AuthChangeEvent.signedIn) {
        // ✅ User logged in — start realtime badge stream
        notifProvider.startListening();
      } else if (data.event == AuthChangeEvent.signedOut) {
        // ✅ User logged out — stop stream and clear badge
        notifProvider.stopListening();
        notifProvider.clear();
      }
    });

    // ✅ Handle cold start — if user is already logged in when app launches
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationProvider>().startListening();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CampusEventsApp();
  }
}