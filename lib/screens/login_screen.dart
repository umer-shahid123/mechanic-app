import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:mechanic_app/screens/admin/admin_login_screen.dart';
import 'package:mechanic_app/screens/admin_dashboard_screen.dart';
import 'package:mechanic_app/screens/forgot_password_screen.dart';
import 'package:mechanic_app/screens/home_screen.dart';
import 'package:mechanic_app/screens/mechanic_home_screen.dart';
import 'package:mechanic_app/screens/signup_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isUser = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle();
        final role = profile?['role'] ?? 'customer';

        if (!mounted) return;

        Widget nextScreen;
        if (role == 'admin') {
          nextScreen = const AdminDashboardScreen();
        } else if (role == 'mechanic') {
          nextScreen = const MechanicHomeScreen();
        } else {
          nextScreen = const HomeScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      // CONFIGURATION STEPS:
      // 1. Go to Google Cloud Console (https://console.cloud.google.com/)
      // 2. Select your project and go to "APIs & Services" > "Credentials"
      // 3. Create an OAuth 2.0 Client ID for "Web application"
      // 4. Copy the "Client ID" and paste it into [webClientId] below.
      // 5. Ensure you have added your SHA-1 fingerprint (from './gradlew signingReport' in Android folder) 
      //    to your Firebase/Google project for the Android App.
      // 6. Ensure Google Sign-In is ENABLED in your Supabase Dashboard under Authentication > Providers.
      
      const webClientId = '8736109096-oi52oklqbogtjtrupip0tm6r6m6rbkhi.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: webClientId,
        serverClientId: kIsWeb ? null : webClientId,
      );

      // Sign out first to ensure account selection dialog appears if needed
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Google Sign-In failed: No ID Token received.';
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        // Ensure profile exists after social login
        await _ensureProfileExists(response.user!);
        await _postAuthRedirect(response.user!.id);
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Google Login Error: $e';
        if (e.toString().contains('k1.d: 10') || e.toString().contains('7:')) {
          msg = 'Google Login Configuration Error (Code 10/7). \n\nChecklist:\n1. Is Web Client ID correct?\n2. Is SHA-1 fingerprint added to Firebase/Google Cloud?\n3. Is Google Sign-In enabled in Supabase Dashboard?';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg), 
            backgroundColor: Colors.red, 
            duration: const Duration(seconds: 8),
            action: SnackBarAction(label: 'Help', textColor: Colors.white, onPressed: () {
              // Open docs or show more info
            }),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Ensures a profile record exists in the database for social logins.
  Future<void> _ensureProfileExists(User user) async {
    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('profiles').insert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'Google User',
        'email': user.email,
        'role': _isUser ? 'customer' : 'mechanic',
        'avatar_url': user.userMetadata?['avatar_url'],
        'verification_status': 'unverified',
      });
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleIdCredential.identityToken;
      if (idToken == null) {
        throw 'No ID Token found from Apple.';
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.user != null) {
        await _postAuthRedirect(response.user!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple Login Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> _postAuthRedirect(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    final role = profile?['role'] ?? 'customer';

    if (!mounted) return;

    Widget nextScreen;
    if (role == 'admin') {
      nextScreen = const AdminDashboardScreen();
    } else if (role == 'mechanic') {
      nextScreen = const MechanicHomeScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              );
            },
            icon: Icon(
              Icons.admin_panel_settings_rounded,
              color: isDark ? AppColors.neonGreen : AppColors.secondary,
            ),
            tooltip: 'Admin Login',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isUser ? 'Welcome Back!' : 'Mechanic Login',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Switch(
                  value: _isUser,
                  onChanged: (val) => setState(() => _isUser = val),
                  activeThumbColor: isDark
                      ? AppColors.neonGreen
                      : AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _isUser ? 'Login to continue' : 'Partner account access',
              style: TextStyle(
                color: isDark ? AppColors.darkGrey : AppColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'Email or Phone',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: isDark ? AppColors.neonGreen : AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white10 : AppColors.divider,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or continue with',
                    style: TextStyle(
                      color: isDark ? AppColors.darkGrey : AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white10 : AppColors.divider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialBtn(
                  Icons.g_mobiledata_rounded, 
                  Colors.red, 
                  isDark,
                  onTap: () => _handleGoogleLogin(),
                ),
                const SizedBox(width: 16),
                _buildSocialBtn(
                  Icons.apple_rounded,
                  isDark ? Colors.white : Colors.black,
                  isDark,
                  onTap: () => _handleAppleLogin(),
                ),
                const SizedBox(width: 16),
                _buildSocialBtn(Icons.facebook_rounded, Colors.blue, isDark),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isUser ? "Don't have an account? " : "Not registered as partner? ",
                  style: TextStyle(
                    color: isDark ? AppColors.darkGrey : AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpScreen(isUser: _isUser),
                      ),
                    );
                  },
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: isDark ? AppColors.neonGreen : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isUser = !_isUser),
                    child: Text(
                      _isUser ? 'Switch to Mechanic Login' : 'Switch to User Login',
                      style: TextStyle(
                        color: isDark ? AppColors.neonGreen : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                      );
                    },
                    icon: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 16,
                      color: isDark ? AppColors.neonGreen : AppColors.secondary,
                    ),
                    label: Text(
                      'Access Admin Portal',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.divider,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark ? [] : AppColors.softShadow,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
