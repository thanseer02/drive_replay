import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_tracker/features/settings/viewmodel/app_icon_viewmodel.dart';
import 'package:drive_tracker/themes/app_text_styles.dart';

class AppIconSection extends StatelessWidget {
  const AppIconSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Text(
            'Change App Icon'.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: strokeColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<AppIconViewModel>(
              builder: (context, viewModel, child) {
                if (!viewModel.initialized) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!viewModel.isSupported) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Dynamic app icons are not supported on this device/platform.',
                      style: AppTextStyles.tsw500,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Combine default and available icons
                final icons = ['default', ...viewModel.availableIcons];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: icons.length,
                  itemBuilder: (context, index) {
                    final iconName = icons[index];
                    final isActive = viewModel.currentIcon == iconName;
                    
                    return _buildIconItem(
                      context: context,
                      iconName: iconName,
                      isActive: isActive,
                      theme: theme,
                      viewModel: viewModel,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconItem({
    required BuildContext context,
    required String iconName,
    required bool isActive,
    required ThemeData theme,
    required AppIconViewModel viewModel,
  }) {
    // Attempt to load preview image, fallback if missing
    final imagePath = 'assets/app_icons/$iconName.png';
    final displayName = iconName == 'default' ? 'Default' : iconName.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 64,
                height: 64,
                color: Colors.grey.withValues(alpha: 0.2),
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          style: AppTextStyles.tsw700.copyWith(
            fontSize: 12,
            color: isActive ? theme.colorScheme.primary : null,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (!isActive)
          TextButton(
            onPressed: () async {
              try {
                await viewModel.changeIcon(iconName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('App icon changed to $displayName'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: theme.colorScheme.secondary,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to change icon: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: const Size(60, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Set', style: TextStyle(fontSize: 12)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
