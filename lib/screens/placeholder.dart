import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
 
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final int index;
  const PlaceholderScreen({super.key, required this.title, required this.index});
 
  @override
  Widget build(BuildContext context) => AppShell(
        title: title,
        currentIndex: index,
        child: const Center(child: Text('Em breve', style: TextStyle(color: kGrey))),
      );
}
 
