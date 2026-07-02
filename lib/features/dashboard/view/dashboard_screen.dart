import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';

class DashboardScreen extends StatelessWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drive Replay', style: AppStyles.tsS20W600CFFFFFF),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.white),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.spMin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, Driver', style: AppStyles.tsS16W400CFFFFFF),
              SizedBox(height: 24.spMin),
              _buildStatsCard(),
              SizedBox(height: 40.spMin),
              Center(
                child: SizedBox(
                  width: 200.spMin,
                  height: 60.spMin,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/live_drive'),
                    icon: Icon(Icons.play_arrow, size: 28.spMin),
                    label: Text('Start Trip', style: AppStyles.tsS20W600CFFFFFF),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.spMin),
                      ),
                    ),
                  ),
                ),
              ),
              // Future addition: Recent Trips List
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: EdgeInsets.all(20.spMin),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20.spMin),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Score', '95', AppColors.scoreExcellent),
          _buildStatItem('Trips', '12', AppColors.white),
          _buildStatItem('Distance', '120 km', AppColors.white),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontSize: 24.spMin,
          fontWeight: FontWeight.bold,
          color: valueColor,
        )),
        SizedBox(height: 4.spMin),
        Text(label, style: AppStyles.tsS14W400CB3B3B3),
      ],
    );
  }
}
