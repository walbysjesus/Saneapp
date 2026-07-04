import 'package:flutter/material.dart';

class FeaturedServicesButton extends StatelessWidget {
  final String label;
  final String categoryId;
  final IconData icon;
  const FeaturedServicesButton({required this.label, required this.categoryId, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onPressed: () {
        Navigator.pushNamed(context, '/service-category', arguments: categoryId);
      },
    );
  }
}

