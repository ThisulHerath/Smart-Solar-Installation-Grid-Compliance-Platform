import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/core/utils/validators.dart';
import 'package:smart_solar_mobile/core/widgets/solar_field.dart';
import 'package:smart_solar_mobile/core/navigation/screens/home_screen.dart';

const _orange = SolarColors.lime;
const _ink = SolarColors.text;
const _muted = SolarColors.muted;
const _field = SolarColors.surface;

class RegisterScreen extends StatefulWidget {
  final ApiService? api;
  const RegisterScreen({super.key, this.api});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  String? _challengeId, _error;
  bool _busy = false, _obscure = true, _complete = false;
  int _resendSeconds = 0;
  Timer? _timer;

  String get _fullName =>
      '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [
      _email,
      _firstName,
      _lastName,
      _password,
      _confirm,
      _code
    ]) {
      c.dispose();
    }
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_form.currentState!.validate()) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await (widget.api ?? ApiService()).post(
          '/api/auth/register/request-otp',
          {
            'fullName': _fullName,
            'email': _email.text.trim(),
            'phoneNumber': '',
            'password': _password.text,
          },
          requiresAuth: false);
      if (!mounted) return;
      setState(() {
        _challengeId = result['challengeId'];
        _resendSeconds = result['resendAfterSeconds'];
        _code.clear();
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Enter the complete six-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      await (widget.api ?? ApiService()).post('/api/auth/register',
          {'challengeId': _challengeId, 'code': _code.text},
          requiresAuth: false);
      final success = await auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (success) {
        setState(() => _complete = true);
      } else {
        setState(() => _error = 'Account created. Please return to sign in.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: SolarColors.muted, fontSize: 12),
        filled: true,
        fillColor: _field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: SolarColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: SolarColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _orange, width: 1.5)),
      );

  Widget _input(TextEditingController controller, String hint,
          {String? Function(String?)? validator,
          bool password = false,
          Widget? suffix}) =>
      SolarField(
        controller: controller,
        validator: validator,
        obscureText: password && _obscure,
        style: const TextStyle(color: _ink, fontSize: 13),
        decoration: _decoration(hint).copyWith(suffixIcon: suffix),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SolarColors.background,
        body: Stack(children: [
          const Positioned.fill(bottom: null, child: _RegisterHeader()),
          SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxHeight < 660;
            final horizontal = constraints.maxWidth < 340 ? 17.0 : 28.0;
            final isVerification = _challengeId != null || _complete;
            final top = isVerification
                ? (compact ? 142.0 : 158.0)
                : (compact ? 156.0 : 188.0);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 22),
              child: Center(
                  child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isVerification ? 310 : 420),
                child: _complete
                    ? _completeView(context, constraints.maxHeight - top)
                    : _challengeId == null
                        ? _signupView(compact)
                        : _otpView(compact, constraints.maxHeight - top - 22),
              )),
            );
          })),
        ]),
      );

  Widget _signupView(bool compact) => Form(
        key: _form,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Register',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _ink, fontSize: 25, fontWeight: FontWeight.w800)),
          SizedBox(height: compact ? 18 : 26),
          if (_error != null) _errorBox(),
          _input(_email, 'Email', validator: Validators.email),
          LayoutBuilder(builder: (context, fieldSize) {
            if (fieldSize.maxWidth < 330) {
              return Column(children: [
                _input(_firstName, 'First Name',
                    validator: Validators.required),
                _input(_lastName, 'Last Name', validator: Validators.required),
              ]);
            }
            return Row(children: [
              Expanded(
                  child: _input(_firstName, 'First Name',
                      validator: Validators.required)),
              const SizedBox(width: 12),
              Expanded(
                  child: _input(_lastName, 'Last Name',
                      validator: Validators.required)),
            ]);
          }),
          _input(_password, 'Password',
              validator: Validators.password,
              password: true,
              suffix: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: _orange),
                  onPressed: () => setState(() => _obscure = !_obscure))),
          SolarField(
              controller: _confirm,
              validator: (value) {
                final v = Validators.required(value);
                if (v != null) return v;
                return value == _password.text
                    ? null
                    : 'Passwords do not match.';
              },
              obscureText: _obscure,
              style: const TextStyle(color: _ink, fontSize: 13),
              decoration: _decoration('Confirm Password').copyWith(
                  suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: _orange),
                      onPressed: () => setState(() => _obscure = !_obscure)))),
          SizedBox(height: compact ? 8 : 12),
          _orangeButton(label: 'Next', onPressed: _requestCode),
          SizedBox(height: compact ? 38 : 70),
          _loginLink(),
        ]),
      );

  Widget _otpView(bool compact, double minHeight) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight.clamp(380, 700)),
        child: IntrinsicHeight(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const Text('OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink, fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                  'We sent a verification code to your email.\nEnter the six digits below to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
              SizedBox(height: compact ? 22 : 34),
              if (_error != null) _errorBox(),
              _otpBoxes(),
              const SizedBox(height: 24),
              _orangeButton(label: 'Confirm', onPressed: _verify),
              TextButton(
                  onPressed: _busy || _resendSeconds > 0 ? null : _requestCode,
                  child: Text(
                      _resendSeconds > 0
                          ? 'Resend in ${_resendSeconds}s'
                          : 'Send a new code',
                      style: const TextStyle(fontSize: 10))),
              const Spacer(),
              _loginLink(),
            ])),
      );

  Widget _completeView(BuildContext context, double minHeight) =>
      ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight.clamp(380, 700)),
        child: IntrinsicHeight(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const SizedBox(height: 20),
              const Icon(Icons.emoji_events_rounded, color: _orange, size: 58),
              const SizedBox(height: 22),
              const Text('Congratulation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink, fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                  'We Send You Email Please Check Your Mail And\nComplete Otp Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
              const SizedBox(height: 30),
              _orangeButton(
                  label: 'Complete',
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false)),
              const Spacer(),
            ])),
      );

  Widget _otpBoxes() => Stack(children: [
        SizedBox(
            height: 48,
            child: TextFormField(
              controller: _code,
              focusNode: _codeFocus,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            )),
        Positioned.fill(
            child: IgnorePointer(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                        6,
                        (i) => Container(
                              width: 42,
                              height: 45,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: _field,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: SolarColors.border)),
                              child: Text(
                                  i < _code.text.length ? _code.text[i] : '0',
                                  style: TextStyle(
                                      color:
                                          i < _code.text.length ? _ink : _muted,
                                      fontSize: 13)),
                            ))))),
      ]);

  Widget _orangeButton(
          {required String label, required VoidCallback onPressed}) =>
      SizedBox(
          height: 45,
          child: ElevatedButton(
            onPressed: _busy ? null : onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: _orange.withValues(alpha: .30),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9))),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
          ));

  Widget _errorBox() => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: SolarColors.errorSoft,
              borderRadius: BorderRadius.circular(8)),
          child: Text(_error!,
              style: const TextStyle(color: SolarColors.error, fontSize: 11))));

  Widget _loginLink() =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Already have Account, ',
            style: TextStyle(color: _muted, fontSize: 10)),
        GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text('Login',
                style: TextStyle(
                    color: _orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700))),
      ]);
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final height = (size.maxWidth * .52).clamp(158.0, 205.0);
        return ClipPath(
          clipper: _RegisterHeaderClipper(),
          child: Container(
              height: height,
              padding:
                  EdgeInsets.fromLTRB(size.maxWidth < 360 ? 22 : 28, 28, 22, 0),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SolarColors.primary, _orange])),
              child: const Align(
                  alignment: Alignment.topLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 21),
                    SizedBox(width: 7),
                    Text('smartsolar.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3)),
                  ]))),
        );
      });
}

class _RegisterHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * .48)
    ..quadraticBezierTo(size.width * .20, size.height * .38, size.width * .36,
        size.height * .58)
    ..quadraticBezierTo(size.width * .50, size.height * .75, size.width * .68,
        size.height * .69)
    ..quadraticBezierTo(
        size.width * .82, size.height * .65, size.width, size.height * .83)
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
