import 'package:flutter/material.dart';

import '../services/data.dart';
import '../theme.dart';

class StatusScreen extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const StatusScreen({super.key, required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(icon, size: 56, color: AppColors.accent),
              ),
              const SizedBox(height: 28),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.7, color: AppColors.muted)),
              const SizedBox(height: 36),
              OutlinedButton.icon(
                onPressed: Data.signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل خروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
