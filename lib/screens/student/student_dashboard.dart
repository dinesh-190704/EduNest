import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../login_screen.dart';
import 'student_assignment_screen.dart';
import 'student_attendance_screen.dart';
import '../common/elibrary_screen.dart';
import '../common/tech_news_screen.dart';
import 'update_profile_screen.dart';
import '../common/lost_found_screen.dart';
import '../common/department_resources_screen.dart';
import 'student_result_screen.dart';
import 'simple_student_chat_screen.dart';
import '../../widgets/user_profile_widget.dart';
import '../../models/user_model.dart';
import 'result_screen.dart';
import 'my_leave_applications.dart';
import 'leave_application_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String studentName;
  final String department;
  final String regNo;
  final String year;
  final String section;
  final String imageUrl;

  const StudentDashboard({
    Key? key,
    this.studentName = "John Doe",  // Demo data
    this.department = "Computer Science",
    this.regNo = "CS20220001",
    this.year = "3rd Year",
    this.section = "A",
    this.imageUrl = "https://ui-avatars.com/api/?name=John+Doe",
  }) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();

}

class _StudentDashboardState extends State<StudentDashboard> {
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
      print('Got user update: ${user?.toMap()}');
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
      uid: widget.regNo, // Using regNo as uid for demo
      email: '${widget.regNo.toLowerCase()}@student.edu', // Demo email
      role: 'student',
      name: widget.studentName,
      profileImageUrl: widget.imageUrl,
      department: widget.department,
      year: widget.year,
      studentId: widget.regNo,
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
                    widget.studentName,
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
                          '${widget.department} - ${widget.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.department,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Reg No: ${widget.regNo}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.year,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
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
              builder: (context) => StudentAssignmentScreen(
                studentId: widget.regNo,
                studentName: widget.studentName,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "My Attendance",
        icon: Icons.fact_check,
        color: Colors.green[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAttendanceScreen(
                regNo: widget.regNo,
                studentName: widget.studentName,
                department: widget.department,
                year: widget.year,
                section: widget.section,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Track Bus",
        icon: Icons.directions_bus,
        color: Colors.green[600]!,
        onTap: () => Navigator.pushNamed(context, '/bus-tracking'),
      ),
      _ModuleItem(
        title: "Leave Applications",
        icon: Icons.calendar_today,
        color: Colors.purple[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyLeaveApplications(studentRegNo: widget.regNo),
            ),
          );
        },
      ),
      _ModuleItem(
        title: "Results",
        icon: Icons.assessment,
        color: Colors.red[600]!,
        onTap: () {
          Navigator.pushNamed(context, '/student/search-result');
        },
      ),
      _ModuleItem(
        title: "Events",
        icon: Icons.event_note,
        color: Colors.purple[600]!,
        onTap: () {
          Navigator.pushNamed(context, '/events');
        },
      ),
      _ModuleItem(
        title: "Resources",
        icon: Icons.library_books,
        color: Colors.red[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DepartmentResourcesScreen(),
            ),
          );
        },
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
        title: "Chat",
        icon: Icons.chat,
        color: Colors.teal[600]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleStudentChatScreen(
                studentId: widget.regNo,
                studentName: widget.studentName,
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
