import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bus_provider.dart';
import 'screens/student/bus_tracking_screen.dart';
import 'screens/admin/new_bus_form.dart';
import 'screens/admin/admin_bus_tracking_screen.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/splash_screen.dart';
import 'screens/student/leave_application_screen.dart';
import 'screens/student/my_leave_applications.dart';
import 'screens/admin/leave_applications_dashboard.dart';

import 'screens/common/resource_screen.dart';
import 'screens/common/events_screen.dart';
import 'providers/result_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/results_page.dart';
import 'screens/student/search_result_screen.dart';
import 'screens/admin/event_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduNest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        // Configure text selection theme
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue[700], // Default cursor color for light backgrounds
          selectionColor: Colors.blue.withOpacity(0.3),
          selectionHandleColor: Colors.blue[700]!,
        ),
        // Configure input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          // Dark cursor and text for light background
          prefixIconColor: Colors.grey[700],
          suffixIconColor: Colors.grey[700],
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          // Border styling
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue[700],
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/bus-tracking': (context) => const BusTrackingScreen(),
        '/admin/bus-management': (context) => const NewBusForm(),
        '/admin/bus-tracking': (context) => const AdminBusTrackingScreen(),
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/student/search-result': (context) => const SearchResultScreen(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/events': (context) => const EventsScreen(),
        '/event-upload': (context) => const EventUploadScreen(),
        '/leave-application': (context) => const LeaveApplicationScreen(),
        '/my-leave-applications': (context) => const MyLeaveApplications(),
        '/leave-applications-dashboard': (context) => const LeaveApplicationsDashboard(),
        '/admin/resources': (context) => const ResourceScreen(isAdmin: true),
        '/admin/events': (context) => const EventsScreen(isAdmin: true),
        '/results': (context) => const ResultsPage(isAdmin: false, studentId: 'STU001'),
        '/admin/results': (context) => const ResultsPage(isAdmin: true),

      },
    );
  }
}
