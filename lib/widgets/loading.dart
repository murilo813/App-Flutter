import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const Loading({
    Key? key,
    required this.icon,
    this.size = 70,
    this.color,
  }) : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color ?? Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
