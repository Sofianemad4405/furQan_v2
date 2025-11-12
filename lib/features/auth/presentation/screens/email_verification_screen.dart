import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Required import for BackdropFilter
import 'dart:ui';
import 'dart:async';

// Add emerald color constants (Tailwind-like emerald shades)
const Color _emerald400 = Color(0xFF34D399);
const Color _emerald500 = Color(0xFF10B981);
const Color _emerald600 = Color(0xFF059669);

/// Email Verification Screen for FurQan App
/// Implements liquid glass aesthetics with OTP input
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  final VoidCallback? onBack;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onVerified,
    this.onBack,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isVerifying = false;
  String _error = '';
  int _resendCountdown = 60;
  bool _canResend = false;
  bool _justResent = false;
  Timer? _countdownTimer;

  late AnimationController _iconAnimationController;
  late AnimationController _errorAnimationController;
  late Animation<double> _iconRotation;
  late Animation<double> _errorShake;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Icon animation
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _iconAnimationController.forward();

    // Error shake animation
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _errorShake = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _errorAnimationController,
        curve: Curves.elasticIn,
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _iconAnimationController.dispose();
    _errorAnimationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _handleCodeChange(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All fields filled, verify
        _verifyCode();
      }
    }
  }

  void _handleBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _getCode();
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _error = '';
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isVerifying = false;
    });

    // For demo: accept any 6-digit code
    if (code.length == 6) {
      widget.onVerified();
    } else {
      setState(() {
        _error = 'Invalid verification code. Please try again.';
      });
      _errorAnimationController.forward(from: 0);
      _clearCode();
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _justResent = true;
      _error = '';
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    _startCountdown();

    // Hide success message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _justResent = false;
        });
      }
    });
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return email;

    final masked =
        username[0] +
        '*' * (username.length - 2) +
        username[username.length - 1];
    return '$masked@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF064E3B), // emerald-950
                    const Color(0xFF115E59), // teal-950
                    const Color(0xFF164E63), // cyan-950
                  ]
                : [
                    const Color(0xFFD1FAE5), // emerald-50
                    const Color(0xFFCCFBF1), // teal-50
                    const Color(0xFFCFFAFE), // cyan-50
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background orbs
            _buildAnimatedOrb(
              top: 40,
              left: 40,
              size: 128,
              colors: [_emerald400, Colors.teal.shade400],
              duration: 8,
            ),
            _buildAnimatedOrb(
              top: 160,
              right: 64,
              size: 96,
              colors: [Colors.cyan.shade400, Colors.blue.shade400],
              duration: 6,
            ),
            _buildAnimatedOrb(
              bottom: 128,
              left: 100,
              size: 80,
              colors: [Colors.teal.shade400, _emerald400],
              duration: 4,
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back),
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Centered content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildGlassContainer(context, isDark),
                      ),
                    ),
                  ),

                  // Demo hint
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDemoHint(isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required List<Color> colors,
    required int duration,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(seconds: duration),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + (0.2 * (value < 0.5 ? value * 2 : 2 - value * 2)),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors.map((c) => c.withOpacity(0.2)).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassContainer(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(children: [_buildHeader(isDark), _buildForm(isDark)]),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  _emerald400.withOpacity(0.05),
                  Colors.teal.shade400.withOpacity(0.05),
                  Colors.cyan.shade400.withOpacity(0.05),
                ]
              : [
                  _emerald500.withOpacity(0.1),
                  Colors.teal.shade500.withOpacity(0.1),
                  Colors.cyan.shade500.withOpacity(0.1),
                ],
        ),
      ),
      child: Column(
        children: [
          // Mail icon
          RotationTransition(
            turns: _iconRotation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_emerald500, Colors.teal.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _emerald500.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mail_outline,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isDark
                  ? [_emerald400, Colors.teal.shade400]
                  : [_emerald600, Colors.teal.shade600],
            ).createShader(bounds),
            child: const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            "We've sent a 6-digit verification code to",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Masked email
          Text(
            _maskEmail(widget.email),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? _emerald400 : _emerald600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // OTP Input
          _buildOTPInput(isDark),
          const SizedBox(height: 24),

          // Error message
          if (_error.isNotEmpty)
            AnimatedBuilder(
              animation: _errorShake,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _errorShake.value * (1 - _errorAnimationController.value),
                    0,
                  ),
                  child: child,
                );
              },
              child: Text(
                _error,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Verifying state
          if (_isVerifying)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? _emerald400 : _emerald600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Verifying...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? _emerald400 : _emerald600,
                  ),
                ),
              ],
            ),

          // Success message
          if (_justResent)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: isDark ? _emerald400 : _emerald600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Code sent successfully!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? _emerald400 : _emerald600,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Resend section
          _buildResendSection(isDark),

          const SizedBox(height: 24),

          // Helper text
          _buildHelperText(isDark),
        ],
      ),
    );
  }

  Widget _buildOTPInput(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 4,
            right: index == 5 ? 0 : 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                enabled: !_isVerifying,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[200] : Colors.grey[700],
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _handleCodeChange(index, value),
                onTap: () {
                  _controllers[index].selection = TextSelection.fromPosition(
                    TextPosition(offset: _controllers[index].text.length),
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendSection(bool isDark) {
    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _canResend ? _resendCode : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: _canResend
                    ? (isDark ? _emerald400 : _emerald600)
                    : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                _canResend ? 'Resend Code' : 'Resend in ${_resendCountdown}s',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _canResend
                      ? (isDark ? _emerald400 : _emerald600)
                      : Colors.grey[400],
                  decoration: _canResend ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelperText(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: _emerald500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Check your spam folder if you don't see the email in your inbox.",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoHint(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.black.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Text(
            'Demo Mode: Enter any 6-digit code to verify',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
