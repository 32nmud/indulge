import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:indulge/services/security/encryption_key_service.dart';

/// Screen for setting up or changing the PIN.
/// Shown when user enables PIN protection in settings.
class PinSetupScreen extends StatefulWidget {
  final bool
  isChanging; // true if changing existing PIN, false if setting up new

  const PinSetupScreen({super.key, this.isChanging = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final EncryptionKeyService _keyService = EncryptionKeyService();

  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';
  bool _isLoading = false;

  static const int _pinLength = 4;

  void _onDigitPressed(String digit) {
    if (_isConfirming) {
      if (_confirmPin.length < _pinLength) {
        setState(() {
          _confirmPin += digit;
          _errorMessage = '';
        });
        if (_confirmPin.length == _pinLength) {
          _confirmAndSavePin();
        }
      }
    } else {
      if (_enteredPin.length < _pinLength) {
        setState(() {
          _enteredPin += digit;
          _errorMessage = '';
        });
        if (_enteredPin.length == _pinLength) {
          _moveToConfirm();
        }
      }
    }
  }

  void _onBackspacePressed() {
    if (_isConfirming) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          _errorMessage = '';
        });
      }
    } else {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _errorMessage = '';
        });
      }
    }
  }

  void _moveToConfirm() {
    setState(() {
      _isConfirming = true;
    });
  }

  Future<void> _confirmAndSavePin() async {
    if (_enteredPin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPin = '';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _keyService.setPin(_enteredPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isChanging
                  ? 'PIN changed successfully'
                  : 'PIN set successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving PIN: $e';
        _confirmPin = '';
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
      appBar: AppBar(title: Text(widget.isChanging ? 'Change PIN' : 'Set PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Lock icon
              Icon(
                widget.isChanging ? Icons.lock : Icons.lock_open,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                _isConfirming
                    ? 'Confirm PIN'
                    : (widget.isChanging ? 'Enter New PIN' : 'Create PIN'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Re-enter your PIN to confirm'
                    : 'Create a 4-digit PIN to secure your app',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
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
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              // PIN pad
              _buildPinPad(),
              const Spacer(),
              // Cancel button when confirming
              if (_isConfirming)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isConfirming = false;
                      _confirmPin = '';
                      _errorMessage = '';
                    });
                  },
                  child: const Text('Go Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    final currentPin = _isConfirming ? _confirmPin : _enteredPin;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < currentPin.length;
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
            const SizedBox(width: 80),
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
