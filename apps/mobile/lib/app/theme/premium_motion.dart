import 'package:flutter/animation.dart';

class PremiumMotion {
  const PremiumMotion._();

  static const press = Duration(milliseconds: 120);
  static const settle = Duration(milliseconds: 260);
  static const enter = Duration(milliseconds: 340);
  static const reveal = Duration(milliseconds: 520);
  static const page = Duration(milliseconds: 430);
  static const linger = Duration(milliseconds: 820);

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
  static const gentle = Curves.easeInOutCubic;
}
