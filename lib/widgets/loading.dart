import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final Widget? child;
  final IconData? icon;
  final Color? color;
  final double size;

  const Loading({Key? key, this.child, this.icon, this.color, this.size = 70})
    : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _beginAnimation;
  late Animation<Alignment> _endAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _beginAnimation = Tween<Alignment>(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _endAnimation = Tween<Alignment>(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.child != null) {
      content = widget.child!;
    } else if (widget.icon != null) {
      content = Icon(
        widget.icon,
        size: widget.size,
        color: widget.color ?? Colors.white,
      );
    } else {
      content = const Image(
        image: AssetImage('assets/icons/iconWhite.png'),
        width: 70,
        height: 70,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _beginAnimation.value,
              end: _endAnimation.value,
              colors: const [
                Color(0xFF15803D),
                Color(0xFF16A34A),
                Color(0xFF049271),
              ],
            ),
          ),
          child: Center(child: content),
        );
      },
    );
  }
}
