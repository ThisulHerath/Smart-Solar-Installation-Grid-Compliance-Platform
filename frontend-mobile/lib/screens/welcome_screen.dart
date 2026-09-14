import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

const solarForest = Color(0xFF183C30);
const solarCream = Color(0xFFF7F8F0);
const solarLime = Color(0xFFD4EF83);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    return Theme(
      data: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: solarForest), scaffoldBackgroundColor: solarCream),
      child: Scaffold(
        backgroundColor: solarCream,
        body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            Row(children: [const Icon(Icons.wb_sunny_outlined, color: solarForest, size: 28), const SizedBox(width: 8), const Expanded(child: Text('smartsolar.', overflow: TextOverflow.ellipsis, style: TextStyle(color: solarForest, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1))), TextButton(onPressed: () => open(const LoginScreen()), child: const Text('Log in', style: TextStyle(color: solarForest)))]),
            const SizedBox(height: 35),
            const Text('A BRIGHTER WAY FORWARD', style: TextStyle(color: Color(0xFF67814E), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 18),
            const Text('Your rooftop.\nA brighter tomorrow.', style: TextStyle(color: solarForest, fontSize: 43, height: 1.1, fontWeight: FontWeight.w600, letterSpacing: -2)),
            const SizedBox(height: 18),
            const Text('Plan solar for your home with clear assessments, engineering review, and your next step always within reach.', style: TextStyle(color: Color(0xFF65725C), fontSize: 15, height: 1.7)),
            const SizedBox(height: 24),
            FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: solarForest, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)), onPressed: () => open(const RegisterScreen()), icon: const Icon(Icons.north_east), label: const Text('Start your solar journey', textAlign: TextAlign.center)),
            const SizedBox(height: 12),
            const Text('Log in or register to access our services.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF65725C), fontSize: 12)),
            const SizedBox(height: 26),
            Container(height: 215, decoration: BoxDecoration(color: const Color(0xFFE3ECCF), borderRadius: BorderRadius.circular(28)), child: Stack(alignment: Alignment.center, children: [
              Positioned(right: 32, top: 20, child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: solarLime, shape: BoxShape.circle), child: const Icon(Icons.wb_sunny_outlined, color: solarForest, size: 34))),
              const Positioned(left: 24, top: 28, child: Text('MORE POSSIBILITY.\nSAME ROOFTOP.', style: TextStyle(color: solarForest, fontSize: 10, letterSpacing: 1.4, height: 1.8))),
              const Positioned(bottom: 40, child: Icon(Icons.solar_power_rounded, size: 125, color: solarForest)),
              const Positioned(bottom: 18, child: Text('BUILT FOR SRI LANKAN HOMES', style: TextStyle(color: solarForest, fontSize: 10, letterSpacing: 1.6))),
            ])),
            const SizedBox(height: 32),
            const Text('A clearer path to solar.', style: TextStyle(color: solarForest, fontSize: 27, fontWeight: FontWeight.w600, letterSpacing: -1)),
            const SizedBox(height: 18),
            _service(context, Icons.roofing, '01', 'Know your rooftop', 'Share your electricity usage and roof details to begin.'),
            _service(context, Icons.verified_user_outlined, '02', 'Plan with confidence', 'Connect site inspections and engineering review.'),
            _service(context, Icons.solar_power_outlined, '03', 'Follow your progress', 'Track your proposal and equipment preparation.'),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: solarForest, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Less guesswork.\nMore sunshine.', style: TextStyle(color: solarLime, fontSize: 29, height: 1.2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              const Text('Create an account, verify your email, and make yourself at home in your personal workspace.', style: TextStyle(color: Color(0xFFD2DDCA), height: 1.7)),
              const SizedBox(height: 20),
              FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: solarLime, foregroundColor: solarForest), onPressed: () => open(const RegisterScreen()), icon: const Icon(Icons.arrow_forward), label: const Text('Create your account')),
            ])),
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Text('Smart Solar · Sri Lanka\nFinal installation and grid connection require authorized engineering and utility approval.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF65725C), fontSize: 11, height: 1.8))),
          ],
        )))),
      ),
    );
  }

  Widget _service(BuildContext context, IconData icon, String number, String title, String description) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(color: const Color(0xFFEDF0E3), borderRadius: BorderRadius.circular(18), child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Icon(icon, color: solarForest, size: 28), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$number · $title', style: const TextStyle(color: solarForest, fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(description, style: const TextStyle(color: Color(0xFF65725C), fontSize: 12, height: 1.6))])), const SizedBox(width: 8), const Icon(Icons.north_east, size: 18, color: solarForest)])),
    )));
  }
}
