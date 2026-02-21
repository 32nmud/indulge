import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:indulge/services/security/encryption_key_service.dart';
import 'package:indulge/services/security/database_encryption_service.dart';
import 'package:indulge/services/database_connection_service.dart';

/// Screen that requires PIN entry before accessing the app.
/// Shown on app startup when PIN protection is enabled.
class PinEntryScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const PinEntryScreen({super.key, required this.onSuccess});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final EncryptionKeyService _keyService = EncryptionKeyService();
  final DatabaseEncryptionService _encryptionService =
      DatabaseEncryptionService();

  String _enteredPin = '';
  String _errorMessage = '';
  bool _isLoading = false;
  static const int _pinLength = 4;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      // Auto-submit when PIN is complete
      if (_enteredPin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isValid = await _keyService.verifyPin(_enteredPin);

      if (isValid) {
        // Get encryption key and initialize database
        final encryptionKey = await _encryptionService.getEncryptionKey();
        await DatabaseConnectionService.instance.initialize(
          encryptionKey: encryptionKey,
        );

        if (mounted) {
          // Call the success callback to unlock the app
          widget.onSuccess();
        }
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _enteredPin = '';
        });
        // Haptic feedback for error
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying PIN: $e';
        _enteredPin = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Lock icon
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Enter PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to access the app',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // PIN dots
              _buildPinDots(),
              const SizedBox(height: 16),
              // Error message
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 32),
              // PIN pad
              _buildPinPad(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < _enteredPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: _errorMessage.isNotEmpty
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('1'),
            _buildPinButton('2'),
            _buildPinButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('4'),
            _buildPinButton('5'),
            _buildPinButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPinButton('7'),
            _buildPinButton('8'),
            _buildPinButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80), // Empty space
            _buildPinButton('0'),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildPinButton(String digit) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _onDigitPressed(digit),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return SizedBox(
      width: 80,
      height: 80,
      child: IconButton(
        onPressed: _isLoading ? null : _onBackspacePressed,
        icon: const Icon(Icons.backspace_outlined),
        iconSize: 28,
      ),
    );
  }
}
