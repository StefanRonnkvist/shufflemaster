import 'package:flutter/material.dart';

const binaryShufflePlaceValues = [32, 16, 8, 4, 2, 1];

class BinaryShuffleSelectors extends StatelessWidget {
  const BinaryShuffleSelectors({
    required this.value,
    this.processingValue,
    this.onChanged,
    this.spacing = 12,
    super.key,
  });

  final int value;
  final int? processingValue;
  final ValueChanged<int>? onChanged;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (
          var index = 0;
          index < binaryShufflePlaceValues.length;
          index++
        ) ...[
          _BinaryShuffleSelector(
            value: binaryShufflePlaceValues[index],
            selectedValue: value,
            isProcessing: processingValue == binaryShufflePlaceValues[index],
            onChanged: onChanged,
          ),
          if (index != binaryShufflePlaceValues.length - 1)
            SizedBox(width: spacing),
        ],
      ],
    );
  }
}

class _BinaryShuffleSelector extends StatelessWidget {
  const _BinaryShuffleSelector({
    required this.value,
    required this.selectedValue,
    required this.isProcessing,
    required this.onChanged,
  });

  final int value;
  final int selectedValue;
  final bool isProcessing;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isSet = selectedValue & value != 0;
    final isZeroValue = selectedValue == 0;
    final isIgnored = selectedValue > 0 && value > selectedValue;
    final nextValue = selectedValue ^ value;
    final canSelect = onChanged != null && nextValue <= 51;

    return Semantics(
      key: ValueKey('binary-shuffle-selector-$value'),
      button: onChanged != null,
      selected: isSet,
      label: 'Binary place $value',
      child: InkWell(
        onTap: canSelect ? () => onChanged!(nextValue) : null,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isZeroValue
                      ? Colors.yellow
                      : isIgnored
                      ? Colors.red
                      : isSet
                      ? Colors.white
                      : Colors.black,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isZeroValue || isIgnored
                    ? 'Ignore'
                    : isSet
                    ? 'In'
                    : 'Out',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                child: isProcessing
                    ? const Icon(
                        Icons.arrow_upward,
                        color: Color(0xFFFFD700),
                        size: 24,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
