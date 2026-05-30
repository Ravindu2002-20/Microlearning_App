import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/repositaries/auth_repository.dart';
import 'core/services/context_engine_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

void main() async {
  // Clear, direct initialization statement without extra characters
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qjbcmjmaowvxlitvzrqh.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqYmNtam1hb3d2eGxpdHZ6cnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwMzY0NzcsImV4cCI6MjA5NTYxMjQ3N30.uCC1_9uupE4GULc0_eAqxiQyMPnvU0m6KmDcHGfTma4',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Because Supabase caches user session tokens locally, we check for a valid login immediately [cite: 288]
    final authRepo = ref.watch(authRepositoryProvider);
    final User? initialUser = authRepo.currentSessionUser;

    return MaterialApp(
      title: 'Context Adaptive Microlearning',
      // Clean Material 3 Dark Theme Configuration 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Persistent Session Routing: Skip login if token is found [cite: 287, 289]
      home: initialUser != null
          ? const MainSwipeFeedScreen() // User session cached, bypass login [cite: 281]
          : const LoginRegistrationScreen(), // Needs credentials [cite: 281]
    );
  }
}

class MainSwipeFeedScreen extends StatefulWidget {
  const MainSwipeFeedScreen({super.key});

  @override
  State<MainSwipeFeedScreen> createState() => _MainSwipeFeedScreenState();
}

class _MainSwipeFeedScreenState extends State<MainSwipeFeedScreen> {
  // Instantiate the hardware context engine [cite: 299]
  final ContextEngineService _contextEngine = ContextEngineService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Context Engine Monitor")),
      body: Center(
        child: StreamBuilder<UserContextState>(
          stream: _contextEngine.contextStream,
          builder: (context, snapshot) {
            // Defensive handling for hardware permission errors 
            if (snapshot.hasError) {
              return Text("Sensor Error: ${snapshot.error}");
            }
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final state = snapshot.data!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.isInMotion ? Icons.directions_walk : Icons.airline_seat_recline_extra,
                  size: 80,
                  color: state.isInMotion ? Colors.orange : Colors.green,
                ),
                const SizedBox(height: 20),
                Text(
                  "Motion Detected: ${state.isInMotion ? 'WALKING' : 'STATIONARY'}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                Icon(
                  state.networkStrength == AppNetworkStrength.strong ? Icons.signal_wifi_4_bar : Icons.network_check,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                Text(
                  "Network Profile: ${state.networkStrength.name.toUpperCase()}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Placeholder for your actual login screen [cite: 284, 285]
class LoginRegistrationScreen extends StatelessWidget {
  const LoginRegistrationScreen({super.key});
  
  @override 
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Login/Registration Screen"))); 
}