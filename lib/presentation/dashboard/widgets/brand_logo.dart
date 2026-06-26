import 'dart:io';
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final String? icon;
  final String name;
  final double size;

  const BrandLogo({
    super.key,
    required this.name,
    this.icon,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final nameLower = name.toLowerCase();

    if (nameLower.contains('bkash')) {
      return _buildBkash();
    } else if (nameLower.contains('nagad')) {
      return _buildNagad();
    } else if (nameLower.contains('rocket')) {
      return _buildRocket();
    } else if (nameLower.contains('upay')) {
      return _buildUpay();
    } else if (nameLower.contains('mcash')) {
      return _buildMCash();
    } else if (nameLower.contains('tap')) {
      return _buildTap();
    } else if (nameLower.contains('mycash')) {
      return _buildMyCash();
    } else if (nameLower.contains('surecash') || nameLower.contains('sure cash')) {
      return _buildSureCash();
    } else if (nameLower.contains('cellfin')) {
      return _buildCellFin();
    } else if (nameLower.contains('pocket')) {
      return _buildPocket();
    } else if (nameLower.contains('binimoy')) {
      return _buildBinimoy();
    } else if (nameLower.contains('debit')) {
      return _buildDebitCard();
    } else if (nameLower.contains('credit') || nameLower.contains('card')) {
      return _buildCreditCard();
    } else if (nameLower.contains('cash')) {
      return _buildCash();
    } else if (nameLower.contains('bank')) {
      return _buildBank();
    }

    // Fallback to emoji
    return Center(
      child: Text(
        icon ?? '💰',
        style: TextStyle(fontSize: size),
      ),
    );
  }

  // --- নতুন ইমেজ ভিত্তিক উইজেটসমূহ ---

  Widget _buildBkash() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.35),
      child: Image.asset(
        'assets/images/bkash.png',
        width: size * 1.5,
        height: size * 1.5,
        fit: BoxFit.cover,
        // যদি আপনি একদম পিসির ডিরেক্ট পাথ ব্যবহার করতে চান (শুধু ডেস্কটপ অ্যাপের জন্য),
        // তবে ওপরের Image.asset কেটে নিচের লাইনটি কমেন্ট আউট মুক্ত করুন:
        // child: Image.file(File(r"C:\Users\Zahid\OneDrive\Desktop\bkash.png")),
      ),
    );
  }

  Widget _buildNagad() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.35),
      child: Image.asset(
        'assets/images/nagad.png',
        width: size * 1.5,
        height: size * 1.5,
        fit: BoxFit.cover,
        // ডিরেক্ট পিসির পাথের জন্য:
        // child: Image.file(File(r"C:\Users\Zahid\OneDrive\Desktop\Nagad.png")),
      ),
    );
  }

  Widget _buildRocket() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.35),
      child: Image.asset(
        'assets/images/rocket.png',
        width: size * 1.5,
        height: size * 1.5,
        fit: BoxFit.cover,
        // ডিরেক্ট পিসির পাথের জন্য:
        // child: Image.file(File(r"C:\Users\Zahid\OneDrive\Desktop\rocket.png")),
      ),
    );
  }

  // --- আগের কাস্টম পেইন্টার উইজেটসমূহ (বাকি মেথডগুলোর জন্য) ---

  Widget _buildUpay() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(color: const Color(0xFFFFD400), width: 1.5),
      ),
      child: CustomPaint(
        painter: _UpayPainter(),
      ),
    );
  }

  Widget _buildMCash() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFF059669),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: CustomPaint(
        painter: _MCashPainter(),
      ),
    );
  }

  Widget _buildTap() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE11D48), width: 1.5),
      ),
      child: CustomPaint(
        painter: _TapPainter(),
      ),
    );
  }

  Widget _buildMyCash() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: CustomPaint(
        painter: _MyCashPainter(),
      ),
    );
  }

  Widget _buildSureCash() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(color: const Color(0xFF0072BC), width: 1.5),
      ),
      child: CustomPaint(
        painter: _SureCashPainter(),
      ),
    );
  }

  Widget _buildOkWallet() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFFE2136E),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: CustomPaint(
        painter: _OkWalletPainter(),
      ),
    );
  }

  Widget _buildCellFin() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
      ),
      child: Center(
        child: Text('🌀', style: TextStyle(fontSize: size * 0.95)),
      ),
    );
  }

  Widget _buildPocket() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(
        child: Text('👛', style: TextStyle(fontSize: size * 0.95)),
      ),
    );
  }

  Widget _buildBinimoy() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: const BoxDecoration(
        color: Color(0xFF059669),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text('🔄', style: TextStyle(fontSize: size * 0.95)),
      ),
    );
  }

  Widget _buildDebitCard() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(
        child: Text('💳', style: TextStyle(fontSize: size * 0.95)),
      ),
    );
  }

  Widget _buildCreditCard() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(
        child: Text('💳', style: TextStyle(fontSize: size * 0.95)),
      ),
    );
  }

  Widget _buildCash() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(
        child: Text('💵', style: TextStyle(fontSize: size * 0.95)),
      ),
    );
  }

  Widget _buildBank() {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(
        child: Text('🏦', style: TextStyle(fontSize: size * 0.95)),
      ),
    );
  }
}

// --- Custom Painters ---

class _UpayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paintYellow = Paint()
      ..color = const Color(0xFFFFD400)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final paintBlue = Paint()
      ..color = const Color(0xFF0072BC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawArc(
      Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.4, h * 0.4),
      3.14 * 0.5,
      3.14 * 1.5,
      false,
      paintYellow,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.4, h * 0.3, w * 0.4, h * 0.4),
      -3.14 * 0.5,
      3.14 * 1.5,
      false,
      paintBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MCashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.7, h * 0.2)
      ..lineTo(w * 0.9, h * 0.4)
      ..lineTo(w * 0.9, h * 0.7)
      ..lineTo(w * 0.7, h * 0.9)
      ..lineTo(w * 0.3, h * 0.9)
      ..lineTo(w * 0.1, h * 0.7)
      ..lineTo(w * 0.1, h * 0.4)
      ..close();
    canvas.drawPath(path, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'M',
        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.5 - textPainter.width / 2, h * 0.5 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintGreen = Paint()
      ..color = const Color(0xFF00A651)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawArc(
      Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7),
      0,
      3.14 * 2,
      false,
      paintGreen,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'tap',
        style: TextStyle(color: Color(0xFFE11D48), fontSize: 11, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.5 - textPainter.width / 2, h * 0.5 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MyCashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(w * 0.2, h * 0.3)
      ..quadraticBezierTo(w * 0.4, h * 0.2, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.6, h * 0.8, w * 0.8, h * 0.7);
    canvas.drawPath(path, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'MY',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.5 - textPainter.width / 2, h * 0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SureCashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = const Color(0xFF0072BC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path()
      ..moveTo(w * 0.25, h * 0.3)
      ..cubicTo(w * 0.6, h * 0.1, w * 0.4, h * 0.9, w * 0.75, h * 0.7);
    canvas.drawPath(path, paint);

    final paintDot = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.7, h * 0.35), 3.0, paintDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OkWalletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintSmile = Paint()
      ..color = const Color(0xFFFFD400)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.35, paintSmile);

    final paintFace = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(w * 0.4, h * 0.42), 1.5, paintFace..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.6, h * 0.42), 1.5, paintFace..style = PaintingStyle.fill);

    canvas.drawArc(
      Rect.fromLTWH(w * 0.35, h * 0.45, w * 0.3, h * 0.25),
      0.1,
      2.9,
      false,
      paintFace..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}