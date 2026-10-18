import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste2Taste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: W2T.butter,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: Scaffold(
        backgroundColor: W2T.cream,
        body: Center(
          child: Text(
            'Waste2Taste',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: W2T.butter,
            ),
          ),
        ),
      ),
    );
  }
}