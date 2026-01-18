import 'package:flutter/material.dart';
import 'app/saneapp.dart';
import 'core/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const SaneApp());
}
