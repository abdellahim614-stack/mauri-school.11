```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SchoolSecretaryUserApp());
}

/// إعدادات الربط السحابي وبيانات المدير
class AppConfig {
  // رقم الواتساب الخاص بالمدير
  static const String adminWhatsApp = '22248584627';
  static const String displayPhone = '48584627';
  static const String subscriptionPriceText = '200 أوقية جديدة للسنة الكاملة';

  // رابط قاعدة البيانات السحابية المجانية الخاصة بك (Firebase Realtime Database)
  static const String databaseUrl =
      'https://mauri-school-6d5f1-default-rtdb.firebaseio.com';
}

/// بيانات الولايات والمقاطعات الموريتانية (مطابقة للصور المرفقة)
const Map<String, List<String>> mauritaniaWilayas = {
  'اترارزه': ['روصو', 'بتلميت', 'المذرذرة', 'اركيز', 'كرمسين', 'واد الناقة'],
  'آدرار': ['أطار', 'شنقيط', 'أوجفت', 'وادان'],
  'الحوض الشرقي': [
    'النعمة',
    'تمبدغة',
    'باسكنو',
    'جكني',
    'آمرج',
    'ولاته',
    'عدل بكرو'
  ],
  'الحوض الغربي': ['العيون', 'طينطان', 'كوبني', 'تامشكط', 'الطويل'],
  'انشيري': ['أكجوجت', 'بنشاب'],
  'لبراكنه': ['ألاك', 'بوغي', 'مقطع لحجار', 'بابابي', 'امبان'],
  'كوركول': ['كيهيدي', 'مقامة', 'امبود', 'لكصيبة 1'],
  'لعصابه': ['كيفة', 'كرو', 'باركيول', 'كنكوصة', 'بومديد'],
  'كيدي ماغا': ['سيلبابي', 'ولد ينج', 'غابو', 'ومبو'],
  'تكانت': ['تجكجة', 'المجرية', 'تيشيت'],
  'تيرس زمور': ['زويرات', 'ازويرات', 'فديرك', 'بير أم اكرين'],
  'داخلة نواذيبو': ['نواذيبو', 'الشامي'],
  'نواكشوط الشمالية': ['دار النعيم', 'تيارت', 'توجنين'],
  'نواكشوط الغربية': ['تفرغ زينة', 'لكصر', 'السبخة'],
  'نواكشوط الجنوبية': ['عرفات', 'الميناء', 'الرياض'],
};

/// المراحل والفصول الدراسية (مطابقة للصور 1000185280 - 1000185284)
const Map<String, List<String>> educationLevels = {
  'أساسي': ['1 أساسي', '2 أساسي', '3 أساسي', '4 أساسي', '5 أساسي', '6 أساسي'],
  'إعدادي': ['1 إعدادي', '2 إعدادي', '3 إعدادي', '4 إعدادي'],
  'ثانوي': ['1 ثانوي', '2 ثانوي', '3 ثانوي'],
};

class SchoolSecretaryUserApp extends StatelessWidget {
  const SchoolSecretaryUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سكرتير المدرسة',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: const Color(0xFFEBEFF5),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AuthGateScreen(),
    );
  }
}

/// خدمة إدارة الحساب، التفعيل السحابي، وحفظ المدارس والأقسام محلياً
class LocalAndCloudService {
  static const String _prefPhone = 'teacher_phone';
  static const String _prefName = 'teacher_name';
  static const String _prefPassword = 'teacher_password';
  static const String _prefIsPaid = 'teacher_is_paid';
  static const String _prefSchools = 'saved_schools_json';
  static const String _prefClasses = 'saved_classes_json';

  /// تسجيل حساب معلم جديد أو تسجيل الدخول
  static Future<String?> registerOrLogin({
    required String phone,
    required String password,
    String? fullName,
    required bool isRegister,
  }) async {
    final cleanPhone = phone.trim().replaceAll(' ', '');
    final cleanPass = password.trim();
    final prefs = await SharedPreferences.getInstance();

    try {
      final url =
          Uri.parse('${AppConfig.databaseUrl}/teachers/$cleanPhone.json');
      final response =
          await http.get(url).timeout(const Duration(seconds: 8));

      if (isRegister) {
        if (response.statusCode == 200 && response.body != 'null') {
          return 'رقم الهاتف هذا مسجل مسبقاً، يرجى اختيار "تسجيل الدخول".';
        }
        final newTeacherData = {
          'phone': cleanPhone,
          'name': fullName?.trim() ?? 'معلم',
          'password': cleanPass,
          'isPaid': false,
          'createdAt': DateTime.now().toIso8601String(),
        };
        await http.put(
          url,
          body: jsonEncode(newTeacherData),
        );
        await _saveUserLocally(
          prefs,
          phone: cleanPhone,
          name: fullName?.trim() ?? 'معلم',
          password: cleanPass,
          isPaid: false,
        );
        return null;
      } else {
        // تسجيل الدخول
        if (response.statusCode == 200 && response.body != 'null') {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['password'] != cleanPass) {
            return 'كلمة المرور غير صحيحة.';
          }
          await _saveUserLocally(
            prefs,
            phone: cleanPhone,
            name: data['name']?.toString() ?? 'معلم',
            password: cleanPass,
            isPaid: data['isPaid'] == true,
          );
          return null;
        } else {
          return 'لا يوجد حساب بهذا الرقم، يرجى إنشاء حساب جديد أولاً.';
        }
      }
    } catch (_) {
      // في حال عدم وجود إنترنت، نتحقق من البيانات المحفوظة محلياً
    }

    final savedPhone = prefs.getString(_prefPhone);
    final savedPass = prefs.getString(_prefPassword);

    if (isRegister) {
      await _saveUserLocally(
        prefs,
        phone: cleanPhone,
        name: fullName?.trim() ?? 'معلم',
        password: cleanPass,
        isPaid: false,
      );
      return null;
    } else {
      if (savedPhone == cleanPhone && savedPass == cleanPass) {
        return null;
      }
      return 'تعذر الاتصال بالخادم، يرجى التأكد من اتصالك بالإنترنت.';
    }
  }

  static Future<void> _saveUserLocally(
    SharedPreferences prefs, {
    required String phone,
    required String name,
    required String password,
    required bool isPaid,
  }) async {
    await prefs.setString(_prefPhone, phone);
    await prefs.setString(_prefName, name);
    await prefs.setString(_prefPassword, password);
    await prefs.setBool(_prefIsPaid, isPaid);
  }

  /// التحقق من حالة التفعيل عند ضغط المعلم على زر "تحديث"
  static Future<bool> refreshSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_prefPhone);
    if (phone == null || phone.isEmpty) return false;

    try {
      final url = Uri.parse('${AppConfig.databaseUrl}/teachers/$phone.json');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bool isPaid = data['isPaid'] == true;
        await prefs.setBool(_prefIsPaid, isPaid);
        return isPaid;
      }
    } catch (_) {
      // إذا لم يتوفر اتصال، نُرجع الحالة المحفوظة محلياً
    }
    return prefs.getBool(_prefIsPaid) ?? false;
  }

  static Future<Map<String, dynamic>?> getCurrentTeacher() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_prefPhone);
    if (phone == null || phone.isEmpty) return null;
    return {
      'phone': phone,
      'name': prefs.getString(_prefName) ?? 'معلم',
      'isPaid': prefs.getBool(_prefIsPaid) ?? false,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPhone);
  }

  /// حفظ واسترجاع المدارس محلياً (بدون إنترنت)
  static Future<List<Map<String, dynamic>>> getSchools(String year) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefSchools);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => Map<String, dynamic>.from(e))
        .where((s) => s['year'] == year)
        .toList();
  }

  static Future<void> addSchool(Map<String, dynamic> school) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefSchools);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];
    list.add(school);
    await prefs.setString(_prefSchools, jsonEncode(list));
  }

  /// حفظ واسترجاع الأقسام محلياً (بدون إنترنت)
  static Future<List<Map<String, dynamic>>> getClasses(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefClasses);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => Map<String, dynamic>.from(e))
        .where((c) => c['schoolId'] == schoolId)
        .toList();
  }

  static Future<void> addClass(Map<String, dynamic> classItem) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefClasses);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];
    list.add(classItem);
    await prefs.setString(_prefClasses, jsonEncode(list));
  }
}

/// بوابة التحقق من تسجيل دخول المعلم
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _loading = true;
  Map<String, dynamic>? _teacher;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  Future<void> _loadTeacher() async {
    final t = await LocalAndCloudService.getCurrentTeacher();
    if (!mounted) return;
    setState(() {
      _teacher = t;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_teacher == null) {
      return TeacherAuthScreen(onAuthSuccess: _loadTeacher);
    }
    return AcademicYearsScreen(
      teacher: _teacher!,
      onLogout: () async {
        await LocalAndCloudService.logout();
        _loadTeacher();
      },
    );
  }
}

/// شاشة تسجيل حساب جديد أو الدخول برقم الهاتف وكلمة السر
class TeacherAuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const TeacherAuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<TeacherAuthScreen> createState() => _TeacherAuthScreenState();
}

class _TeacherAuthScreenState extends State<TeacherAuthScreen> {
  bool _isRegister = true;
  bool _submitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (phone.isEmpty || pass.isEmpty || (_isRegister && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await LocalAndCloudService.registerOrLogin(
      phone: phone,
      password: pass,
      fullName: name,
      isRegister: _isRegister,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    } else {
      widget.onAuthSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        const Icon(Icons.school, size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'سكرتير المدرسة',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegister
                        ? 'إنشاء حساب معلم جديد'
                        : 'تسجيل الدخول إلى حسابك',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  if (_isRegister) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل (مثال: عبد الله الشيخ)',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف (مثال: 48584627)',
                      prefixIcon: const Icon(Icons.phone_android),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة السر',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isRegister ? 'إنشاء الحساب' : 'دخول',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegister = !_isRegister;
                      });
                    },
                    child: Text(
                      _isRegister
                          ? 'لديك حساب بالفعل؟ اضغط هنا لتسجيل الدخول'
                          : 'ليس لديك حساب؟ أنشئ حساباً جديداً',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1. الشاشة الرئيسية: اختيار السنة الدراسية (مطابقة للصورة 1000185269)
class AcademicYearsScreen extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onLogout;

  const AcademicYearsScreen({
    super.key,
    required this.teacher,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سكرتير المدرسة',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      "SECRETAIRE DE L'ECOLE",
                      style: TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF4A90E2)),
              tooltip: 'تسجيل الخروج',
              onPressed: onLogout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلا بك ${teacher['name']}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'اختر سنة دراسية',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildYearCard(
              context,
              yearTitle: '2026 - 2027',
              statusText: 'جارية',
              isCurrent: true,
            ),
            const SizedBox(height: 12),

            _buildYearCard(
              context,
              yearTitle: '2025 - 2026',
              statusText: 'منتهية',
              isCurrent: false,
            ),

            const Spacer(),

            // زر التواصل مع الدعم عبر واتساب كما في الصورة الأولى
            InkWell(
              onTap: () asyn
