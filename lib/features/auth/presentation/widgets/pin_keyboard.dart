import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PinKeyboard extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;

  const PinKeyboard({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(['1', '2', '3']),
        const SizedBox(height: 16),
        _row(['4', '5', '6']),
        const SizedBox(height: 16),
        _row(['7', '8', '9']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (onBiometric != null)
              _actionButton(Icons.fingerprint, onBiometric!)
            else
              const SizedBox(width: 72, height: 72),
            _digitButton('0'),
            _actionButton(Icons.backspace_outlined, onDelete),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map(_digitButton).toList(),
      );

  Widget _digitButton(String digit) => SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(36),
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: () => onDigit(digit),
            child: Center(
              child: Text(
                digit,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _actionButton(IconData icon, VoidCallback onTap) => SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(36),
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: onTap,
            child: Center(
              child: Icon(icon, color: AppColors.textSecondary, size: 28),
            ),
          ),
        ),
      );
}

class PinDots extends StatelessWidget {
  final int length;
  final int filled;

  const PinDots({super.key, this.length = 4, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.textSecondary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
