import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    background: Colors.blue.shade50, // A light blue background
    primary: Color(0xFF64B3FE), // Blue color for primary elements
    secondary: Colors.blue.shade100, // Light blue for secondary elements
    onPrimary: Colors.grey, // Text/icon color on primary (white for contrast)
    onSecondary: Colors.black, // Text/icon color on secondary
    surface: Colors.white, // White background for cards and containers
    onSurface: Colors.black, // Black text/icon color on surface
    inversePrimary: Colors.blue.shade700, // A darker shade of blue for inverse
  ),
);
