import 'package:flutter/material.dart';

import '../../../core/constants/constants.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // NOTE: Repository update wiring is not implemented in this change-set.
    // This screen currently provides the UI skeleton for editing profile fields.
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text('Edit Profile'),
        foregroundColor: AppColors.textPrimaryDark,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingLg,
        ),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.surfaceDark,
              child: const Icon(Icons.person_outline_rounded, size: 38),
            ),
          ),
          SizedBox(height: AppDimensions.spacingXxl),
          TextField(
            decoration: InputDecoration(
              labelText: 'Full name',
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          TextField(
            decoration: InputDecoration(
              labelText: 'Username',
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          TextField(
            decoration: InputDecoration(
              labelText: 'Avatar URL',
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: AppDimensions.spacingXxl),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

