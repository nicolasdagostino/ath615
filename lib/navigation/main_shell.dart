import 'package:flutter/material.dart';
import '../features/booking/booking_screen.dart';
import '../features/workouts/workouts_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/admin/admin_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final screens = [
    const BookingScreen(),
    const WorkoutsScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
    const AdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,

        onTap: (i) {
          setState(() {
            index = i;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,

        backgroundColor: Colors.white,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Booking",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Workouts",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),

          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "Admin"),
        ],
      ),
    );
  }
}
