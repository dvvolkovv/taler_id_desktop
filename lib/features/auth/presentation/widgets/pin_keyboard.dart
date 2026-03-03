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
    final colors = AppColors.of(context);
    return Column(
      children: [
        _row(['1', '2', '3'], colors),
        const SizedBox(height: 16),
        _row(['4', '5', '6'], colors),
        const SizedBox(height: 16),
        _row(['7', '8', '9'], colors),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (onBiometric != null)
              _actionButton(Icons.fingerprint, onBiometric!, colors)
            else
              const SizedBox(width: 72, height: 72),
            _digitButton('0', colors),
            _actionButton(Icons.backspace_outlined, onDelete, colors),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits, AppColorsExtension colors) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map((d) => _digitButton(d, colors)).toList(),
      );

  Widget _digitButton(String digit, AppColorsExtension colors) => SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(36),
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: () => onDigit(digit),
            child: Center(
              child: Text(
                digit,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _actionButton(IconData icon, VoidCallback onTap, AppColorsExtension colors) => SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(36),
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: onTap,
            child: Center(
              child: Icon(icon, color: colors.textSecondary, size: 28),
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
    final colors = AppColors.of(context);
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
            color: active ? colors.primary : Colors.transparent,
            border: Border.all(
              color: active ? colors.primary : colors.textSecondary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
