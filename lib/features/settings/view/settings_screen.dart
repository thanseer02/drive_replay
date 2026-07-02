import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';
import '../../reports/helpers/export_helper.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppStyles.tsS20W600CFFFFFF),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.spMin),
        children: [
          _buildSectionHeader('Preferences'),
          _buildListTile(Icons.speed, 'Speed Units', 'km/h', onTap: () {}),
          _buildListTile(Icons.dark_mode, 'Theme', 'Dark Mode', onTap: () {}),
          _buildListTile(Icons.language, 'Language', 'English', onTap: () {}),
          
          SizedBox(height: 24.spMin),
          _buildSectionHeader('Data & Privacy'),
          _buildListTile(
            Icons.download, 
            'Export Data (CSV)', 
            '', 
            onTap: () => ExportHelper.exportTripsToCSV(),
          ),
          _buildListTile(
            Icons.delete_forever, 
            'Clear All Trips', 
            '', 
            color: AppColors.error, 
            onTap: () {},
          ),
          
          SizedBox(height: 24.spMin),
          _buildSectionHeader('About'),
          _buildListTile(Icons.info_outline, 'App Version', '1.0.0', onTap: null),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.spMin, left: 8.spMin),
      child: Text(
        title.toUpperCase(),
        style: AppStyles.tsS12W400C666666,
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String trailing, {VoidCallback? onTap, Color? color}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.spMin),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.spMin),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.textPrimary),
        title: Text(title, style: AppStyles.tsS16W400CFFFFFF.copyWith(color: color)),
        trailing: trailing.isNotEmpty 
            ? Text(trailing, style: AppStyles.tsS14W400CB3B3B3) 
            : Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
