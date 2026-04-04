import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // REDCap Classic theme colors
  static const Color brightRed = Color(0xFFD40000);
  static const Color lightGray = Color(0xFFFCFCFC);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _controller.forward();

    // Navigate to home screen after animation
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // REDCap appears first (0.0 - 0.4 seconds)
            final redcapProgress = (Curves.easeOut.transform(
              (_controller.value * 2.5).clamp(0.0, 1.0),
            )).clamp(0.0, 1.0);

            // Con appears with delay (0.3 - 0.8 seconds)
            final conProgress = (Curves.easeOut.transform(
              ((_controller.value - 0.12) / 0.4).clamp(0.0, 1.0),
            )).clamp(0.0, 1.0);

            // Hat appears 1 second after Con (1.8 - 2.5 seconds)
            final hatProgress = (Curves.easeOutBack.transform(
              ((_controller.value - 0.72) / 0.28).clamp(0.0, 1.0),
            )).clamp(0.0, 1.0);

            return UnconstrainedBox(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // REDCap - gentle slide from left
                      Transform.translate(
                        offset: Offset(-30 * (1 - redcapProgress), 0),
                        child: Opacity(
                          opacity: redcapProgress,
                          child: const Text(
                            'REDCap',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      // Con - gentle slide from right
                      Transform.translate(
                        offset: Offset(30 * (1 - conProgress), 0),
                        child: Opacity(
                          opacity: conProgress,
                          child: Text(
                            'Con',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              color: brightRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Hat - appears on top of the 'R' after Con animates in
                  Positioned(
                    left: -18,
                    top: 2,
                    child: Transform.scale(
                      scale: hatProgress,
                      child: Opacity(
                        opacity: hatProgress,
                        child: Image.asset(
                          'assets/images/hat.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
