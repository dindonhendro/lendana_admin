import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final Widget child;
  final double width;

  const MyButton({
    super.key,
    required this.onTap,
    required this.child,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Shadow color
              blurRadius: 8, // Blur radius of the shadow
              offset: Offset(0, 4), // Horizontal and vertical offset
              spreadRadius: 2, // Spread radius of the shadow
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Center(child: child),
      ),
    );
  }
}
