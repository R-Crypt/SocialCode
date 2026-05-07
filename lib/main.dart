import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_code/core/theme/app_theme.dart';
import 'package:social_code/features/auth/bloc/auth_bloc.dart';
import 'package:social_code/features/auth/screens/login_screen.dart';
import 'package:social_code/features/auth/screens/dashboard_screen.dart';
import 'package:social_code/services/auth_service.dart';
import 'package:social_code/services/challenge_service.dart';
import 'package:social_code/services/submission_service.dart';
import 'package:social_code/services/report_service.dart';
import 'package:social_code/services/event_service.dart';
import 'package:social_code/services/ticket_service.dart';
import 'package:social_code/features/challenges/bloc/challenges_bloc.dart';
import 'package:social_code/features/events/bloc/events_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vyihctqxmpdbhdzvpkqg.supabase.co',
    anonKey: 'sb_publishable_8K922tNL8hGQX4geoyz8Sg_7K9SOZ5l',
  );

  runApp(const SocialCodeApp());
}

class SocialCodeApp extends StatelessWidget {
  const SocialCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthService()),
        RepositoryProvider(create: (_) => ChallengeService()),
        RepositoryProvider(create: (_) => SubmissionService()),
        RepositoryProvider(create: (_) => ReportService()),
        RepositoryProvider(create: (_) => EventService()),
        RepositoryProvider(create: (_) => TicketService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(ctx.read<AuthService>())..add(AppStarted()),
          ),
          BlocProvider(
            create: (ctx) => ChallengesBloc(ctx.read<ChallengeService>()),
          ),
          BlocProvider(
            create: (ctx) => EventsBloc(ctx.read<EventService>())..add(LoadPublishedEvents()),
          ),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeMode,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'The Social Code',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              onGenerateRoute: (settings) {
                // Check if the URL has messy OAuth query parameters attached
                if (settings.name != null && settings.name!.contains('?code=')) {
                  // Strip them out and push a clean root route
                  return MaterialPageRoute(
                    settings: const RouteSettings(name: '/'),
                    builder: (context) {
                      return BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading || state is AuthInitial) return const _SplashScreen();
                          if (state is Authenticated) return DashboardScreen(user: state.user);
                          return const LoginScreen();
                        },
                      );
                    },
                  );
                }

                // Normal route handling
                return MaterialPageRoute(
                  settings: settings.name == '/' ? const RouteSettings(name: '/') : settings,
                  builder: (context) {
                    return BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading || state is AuthInitial) return const _SplashScreen();
                        if (state is Authenticated) return DashboardScreen(user: state.user);
                        return const LoginScreen();
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryMagenta,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
