import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/solar_theme.dart';
import '../utils/validators.dart';
import '../widgets/solar_field.dart';
import 'home_screen.dart';
import 'register_screen.dart';

const _orange = SolarColors.lime;
const _ink = SolarColors.text;
const _muted = SolarColors.muted;
const _field = SolarColors.surface;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
        _emailController.text.trim(), _passwordController.text);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: SolarColors.muted, fontSize: 12),
        suffixIcon: suffix,
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: SolarColors.background,
      body: Stack(children: [
        const Positioned.fill(bottom: null, child: _OrangeHeader()),
        SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxHeight < 640;
          final horizontal = constraints.maxWidth < 340 ? 16.0 : 23.0;
          final top = compact ? 96.0 : 116.0;
          final bottom = compact ? 14.0 : 24.0;
          final contentHeight = (constraints.maxHeight - top - bottom)
              .clamp(0.0, double.infinity);
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: contentHeight),
                        child: IntrinsicHeight(
                            child: Form(
                                key: _form,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Center(child: _AvatarBadge()),
                                      SizedBox(height: compact ? 8 : 14),
                                      const Text('Login',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: _ink,
                                              fontSize: 25,
                                              fontWeight: FontWeight.w800)),
                                      SizedBox(height: compact ? 14 : 24),
                                      if (auth.errorMessage != null) ...[
                                        Container(
                                            padding: const EdgeInsets.all(11),
                                            decoration: BoxDecoration(
                                                color: SolarColors.errorSoft,
                                                borderRadius:
                                                    BorderRadius.circular(9)),
                                            child: Text(auth.errorMessage!,
                                                style: const TextStyle(
                                                    color: SolarColors.error,
                                                    fontSize: 11))),
                                        const SizedBox(height: 11),
                                      ],
                                      SolarField(
                                        controller: _emailController,
                                        validator: Validators.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        style: const TextStyle(
                                            color: _ink, fontSize: 13),
                                        decoration: _decoration('Email',
                                            suffix: const Icon(
                                                Icons.email_outlined,
                                                color: _muted,
                                                size: 18)),
                                      ),
                                      SolarField(
                                        key: const ValueKey(
                                            'login_password_field'),
                                        controller: _passwordController,
                                        validator: Validators.required,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(
                                            color: _ink, fontSize: 13),
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) {
                                          if (auth.status !=
                                              AuthStatus.authenticating) {
                                            _handleLogin();
                                          }
                                        },
                                        decoration: _decoration('Password',
                                            suffix: IconButton(
                                              tooltip: _obscurePassword
                                                  ? 'Show password'
                                                  : 'Hide password',
                                              icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: _orange,
                                                  size: 18),
                                              onPressed: () => setState(() =>
                                                  _obscurePassword =
                                                      !_obscurePassword),
                                            )),
                                      ),
                                      Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {},
                                            style: TextButton.styleFrom(
                                                foregroundColor: _muted,
                                                textStyle: const TextStyle(
                                                    fontSize: 10)),
                                            child: const Text(
                                                'Forgot Your Password?'),
                                          )),
                                      SizedBox(height: compact ? 2 : 8),
                                      SizedBox(
                                          height: 45,
                                          child: ElevatedButton(
                                            onPressed: auth.status ==
                                                    AuthStatus.authenticating
                                                ? null
                                                : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: _orange,
                                                foregroundColor: Colors.white,
                                                elevation: 2,
                                                shadowColor: _orange.withValues(
                                                    alpha: .3),
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 45),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            9))),
                                            child: auth.status ==
                                                    AuthStatus.authenticating
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2))
                                                : const Text('Login',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                          )),
                                      SizedBox(height: compact ? 14 : 20),
                                      const Divider(
                                          color: SolarColors.border,
                                          thickness: 1),
                                      SizedBox(height: compact ? 6 : 10),
                                      Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            const Text(
                                                "Don't have an account?",
                                                style: TextStyle(
                                                    color: _muted,
                                                    fontSize: 12)),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                            builder: (_) =>
                                                                const RegisterScreen())),
                                                style: TextButton.styleFrom(
                                                    foregroundColor: _orange,
                                                    textStyle: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                child: const Text('Register')),
                                          ]),
                                    ])))))),
          );
        })),
      ]),
    );
  }
}

class _OrangeHeader extends StatelessWidget {
  const _OrangeHeader();
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final headerHeight = (size.maxWidth * .46).clamp(142.0, 182.0);
        return ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
              height: headerHeight,
              padding: const EdgeInsets.fromLTRB(21, 18, 21, 0),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SolarColors.primary, _orange])),
              child: const Align(
                  alignment: Alignment.topLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.wb_sunny_outlined,
                        color: Colors.white, size: 21),
                    SizedBox(width: 5),
                    Text('smartsolar.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.7)),
                  ]))),
        );
      });
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * .73)
    ..quadraticBezierTo(
        size.width * .26, size.height * .55, size.width * .51, size.height * .7)
    ..quadraticBezierTo(
        size.width * .76, size.height * .9, size.width, size.height * .59)
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge();
  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * .30).clamp(96.0, 118.0);
    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: SolarColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: _orange.withValues(alpha: .18),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ]),
      child: Container(
        decoration: const BoxDecoration(
            color: SolarColors.surfaceSoft, shape: BoxShape.circle),
        child: Icon(Icons.person_rounded,
            color: SolarColors.primary, size: size * .76),
      ),
    );
  }
}
