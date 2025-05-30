import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'study_materials_screen.dart';

class DepartmentResourcesScreen extends StatelessWidget {
  final bool isAdmin;

  const DepartmentResourcesScreen({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Department Resources',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildDepartmentTile(
            context,
            'IT',
            Icons.language,
            Colors.green[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: color,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyMaterialsScreen(
                department: title,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
      ),
    );
  }
}
