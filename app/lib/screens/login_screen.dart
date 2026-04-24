import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService.logIn(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
      } else {
        await AuthService.signUp(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
      }
      // Auth state change detected by StreamBuilder in main.dart — it will
      // replace LoginScreen with _RoleRouter automatically.
      // Reset loading so the UI doesn't hang if there's a micro-delay.
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().split(']').last), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / Icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              
              Text(_isLogin ? 'Welcome Back' : 'Create Account', 
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Secure Patient Portal', 
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54)),
              const SizedBox(height: 40),

              // Inputs
              _buildTextField(_emailCtrl, 'Email Address', Icons.email_outlined, false),
              const SizedBox(height: 16),
              _buildTextField(_passwordCtrl, 'Password', Icons.lock_outline, true),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? 'Secure Login' : 'Register Patient', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),

              // Toggle Mode
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Need an account? Register here' : 'Already registered? Log in', 
                    style: GoogleFonts.outfit(color: AppColors.tealLight, fontWeight: FontWeight.w600)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, bool isPassword) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm), borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      ),
    );
  }
}