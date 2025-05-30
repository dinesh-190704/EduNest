import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import 'attendance_screen.dart';
import 'student_list_screen.dart';
import 'attendance_report_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../login_screen.dart';
import 'admin_assignment_screen.dart';
import '../common/elibrary_screen.dart';
import '../common/tech_news_screen.dart';
import '../common/lost_found_screen.dart';
import '../common/department_resources_screen.dart';
import 'simple_admin_chat_screen.dart';
import '../common/events_screen.dart';
import 'admin_events_screen.dart';
import 'result_upload_screen.dart';
import 'result_stats_screen.dart';

import '../../widgets/user_profile_widget.dart';
import '../../models/user_model.dart';

class AdminDashboard extends StatefulWidget {
  final String adminName;
  final String department;
  final String staffId;
  final String imageUrl;

  const AdminDashboard({
    Key? key,
    this.adminName = "Admin User",  // Demo data
    this.department = "Computer Science",
    this.staffId = "STAFF001",
    this.imageUrl = "https://ui-avatars.com/api/?name=Admin+User",
  }) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();

}

class _AdminDashboardState extends State<AdminDashboard> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize current user
    _updateCurrentUser();
  }

  void _updateCurrentUser() {
    final userService = UserService();
    userService.getCurrentUser().listen((user) {
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[700]!,
              Colors.blue[900]!,
              Colors.indigo[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProfileHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _buildDashboardGrid(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = UserModel(
      uid: widget.staffId,
      email: '${widget.staffId.toLowerCase()}@admin.edu', // Demo email
      role: 'admin',
      name: widget.adminName,
      profileImageUrl: widget.imageUrl,
      department: widget.department,
      staffId: widget.staffId,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_currentUser != null) UserProfileWidget(
                user: _currentUser!,
                onProfileUpdated: (String newImageUrl) {
                  // Profile image will be automatically updated through the stream
                  setState(() {
                    _currentUser = _currentUser!.copyWith(profileImageUrl: newImageUrl);
                  });
                },
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.adminName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.department,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Staff ID: ${widget.staffId}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    final modules = [
      _ModuleItem(
        title: "Assignments",
        icon: Icons.assignment,
        color: Colors.blue[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAssignmentScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Mark Attendance",
        icon: Icons.fact_check,
        color: Colors.green[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAttendanceScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Student List",
        icon: Icons.people,
        color: Colors.blue[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentListScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Attendance Reports",
        icon: Icons.analytics,
        color: Colors.purple[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceReportScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Leave Requests",
        icon: Icons.note_add,
        color: Colors.teal[600]!,
        onTap: () {
          Navigator.pushNamed(context, '/leave-applications-dashboard');
        },
      ),
      _ModuleItem(
        title: "Bus Management",
        icon: Icons.directions_bus,
        color: Colors.indigo[600]!,
        onTap: () => Navigator.pushNamed(context, '/admin/bus-management'),
      ),
      _ModuleItem(
        title: "Track Buses",
        icon: Icons.location_on,
        color: Colors.green[600]!,
        onTap: () => Navigator.pushNamed(context, '/admin/bus-tracking'),
      ),
      _ModuleItem(
        title: "E-Library",
        icon: Icons.library_books,
        color: Colors.purple[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ELibraryScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Results",
        icon: Icons.assessment,
        color: Colors.red[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResultUploadScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Result Statistics",
        icon: Icons.analytics,
        color: Colors.orange[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResultStatsScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Tech News",
        icon: Icons.newspaper,
        color: Colors.orange[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TechNewsScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Department Resources",
        icon: Icons.folder_special,
        color: Colors.indigo[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DepartmentResourcesScreen(isAdmin: true),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Chat System",
        icon: Icons.chat,
        color: Colors.teal[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleAdminChatScreen(
                adminId: widget.staffId,
                adminName: widget.adminName,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Lost & Found",
        icon: Icons.search,
        color: Colors.amber[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LostFoundScreen(),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Events",
        icon: Icons.event,
        color: Colors.pink[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventsScreen(isAdmin: true),
            ),
          );
        },
      ),

    ];

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleCard(module);
      },
    );
  }

  Widget _buildModuleCard(_ModuleItem module) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: module.color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                module.icon,
                color: module.color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                module.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (module.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  module.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
