import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SchoolSecretaryUserApp());
}

class AppConfig {
  static const String adminWhatsApp = '22248584627';
  static const String displayPhone = '48584627';
  static const String subscriptionPriceText = '200 أوقية جديدة للسنة الكاملة';
  static const String databaseUrl =
      '[https://mauri-school-6d5f1-default-rtdb.firebaseio.com](https://mauri-school-6d5f1-default-rtdb.firebaseio.com)';
}

const Map<String, List<String>> mauritaniaWilayas = {
  'اترارزه': ['روصو', 'بتلميت', 'المذرذرة', 'اركيز', 'كرمسين', 'واد الناقة'],
  'آدرار': ['أطار', 'شنقيط', 'أوجفت', 'وادان'],
  'الحوض الشرقي': ['النعمة', 'تمبدغة', 'باسكنو', 'جكني', 'آمرج', 'ولاته', 'عدل بكرو'],
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

class LocalAndCloudService {
  static const String _prefPhone = 'teacher_phone';
  static const String _prefName = 'teacher_name';
  static const String _prefPassword = 'teacher_password';
  static const String _prefIsPaid = 'teacher_is_paid';
  static const String _prefSchools = 'saved_schools_json';
  static const String _prefClasses = 'saved_classes_json';

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
      final url = Uri.parse('${AppConfig.databaseUrl}/teachers/$cleanPhone.json');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

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
        await http.put(url, body: jsonEncode(newTeacherData));
        await _saveUserLocally(
          prefs,
          phone: cleanPhone,
          name: fullName?.trim() ?? 'معلم',
          password: cleanPass,
          isPaid: false,
        );
        return null;
      } else {
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
    } catch (_) {}

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
    } catch (_) {}
    return prefs.getBool(_prefIsPaid) ?? false;
  }

  static Future?> getCurrentTeacher() async {
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

  static Future<List>> getSchools(String year) async {
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

  static Future<List>> getClasses(String schoolId) async {
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
                    child: const Icon(Icons.school, size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'سكرتير المدرسة',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegister ? 'إنشاء حساب معلم جديد' : 'تسجيل الدخول إلى حسابك',
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

class AcademicYearsScreen extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onLogout;

  const AcademicYearsScreen({
    super.key,
    required this.teacher,
    required this.onLogout,
  });

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse(
      '[https://wa.me/$](https://wa.me/$){AppConfig.adminWhatsApp}?text=${Uri.encodeComponent("السلام عليكم، أريد الاستفسار عن تطبيق سكرتير المدرسة (رقمي: ${teacher['phone']})")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildYearCard(
    BuildContext context, {
    required String yearTitle,
    required String statusText,
    required bool isCurrent,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchoolsListScreen(
              yearTitle: yearTitle,
              teacher: teacher,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? const Color(0xFF4A90E2) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: isCurrent ? const Color(0xFF4A90E2) : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  yearTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFFE3F2FD)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: isCurrent ? const Color(0xFF1565C0) : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سكرتير المدرسة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
            InkWell(
              onTap: _openWhatsAppSupport,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text(
                      'تواصل مع الدعم الفني عبر واتساب (${AppConfig.displayPhone})',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SchoolsListScreen extends StatefulWidget {
  final String yearTitle;
  final Map<String, dynamic> teacher;

  const SchoolsListScreen({
    super.key,
    required this.yearTitle,
    required this.teacher,
  });

  @override
  State<SchoolsListScreen> createState() => _SchoolsListScreenState();
}

class _SchoolsListScreenState extends State<SchoolsListScreen> {
  List> _schools = [];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    final list = await LocalAndCloudService.getSchools(widget.yearTitle);
    if (!mounted) return;
    setState(() => _schools = list);
  }

  Future<void> _showAddSchoolDialog() async {
    final nameCtrl = TextEditingController();
    String selectedWilaya = mauritaniaWilayas.keys.first;
    String selectedMoughataa = mauritaniaWilayas[selectedWilaya]!.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final moughataas = mauritaniaWilayas[selectedWilaya] ?? [];
            return AlertDialog(
              title: const Text('إضافة مدرسة جديدة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المدرسة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedWilaya,
                      decoration: const InputDecoration(
                        labelText: 'الولاية',
                        border: OutlineInputBorder(),
                      ),
                      items: mauritaniaWilayas.keys
                          .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setDialogState(() {
                          selectedWilaya = val;
                          selectedMoughataa = mauritaniaWilayas[val]!.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedMoughataa,
                      decoration: const InputDecoration(
                        labelText: 'المقاطعة',
                        border: OutlineInputBorder(),
                      ),
                      items: moughataas
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setDialogState(() => selectedMoughataa = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await LocalAndCloudService.addSchool({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'year': widget.yearTitle,
                      'name': nameCtrl.text.trim(),
                      'wilaya': selectedWilaya,
                      'moughataa': selectedMoughataa,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadSchools();
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مدارس السنة (${widget.yearTitle})'),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSchoolDialog,
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مدرسة'),
      ),
      body: _schools.isEmpty
          ? const Center(
              child: Text(
                'لم تقم بإضافة أي مدرسة بعد.\nاضغط على "إضافة مدرسة" بالأسفل للبدء.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _schools.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = _schools[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.account_balance, color: Color(0xFF1565C0)),
                  ),
                  title: Text(
                    s['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${s['wilaya']} -${s['moughataa']}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchoolClassesScreen(
                          school: s,
                          teacher: widget.teacher,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class SchoolClassesScreen extends StatefulWidget {
  final Map<String, dynamic> school;
  final Map<String, dynamic> teacher;

  const SchoolClassesScreen({
    super.key,
    required this.school,
    required this.teacher,
  });

  @override
  State<SchoolClassesScreen> createState() => _SchoolClassesScreenState();
}

class _SchoolClassesScreenState extends State<SchoolClassesScreen> {
  List> _classes = [];
  bool _isPaid = false;
  bool _checkingStatus = false;

  @override
  void initState() {
    super.initState();
    _isPaid = widget.teacher['isPaid'] == true;
    _loadClasses();
    _refreshStatusSilently();
  }

  Future<void> _refreshStatusSilently() async {
    final paid = await LocalAndCloudService.refreshSubscriptionStatus();
    if (!mounted) return;
    setState(() => _isPaid = paid);
  }

  Future<void> _loadClasses() async {
    final list = await LocalAndCloudService.getClasses(widget.school['id'].toString());
    if (!mounted) return;
    setState(() => _classes = list);
  }

  Future<void> _checkSubscriptionButton() async {
    setState(() => _checkingStatus = true);
    final paid = await LocalAndCloudService.refreshSubscriptionStatus();
    if (!mounted) return;
    setState(() {
      _isPaid = paid;
      _checkingStatus = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paid
              ? 'تم تفعيل حسابك بنجاح! يمكنك الآن استخدام كافة الميزات.'
              : 'الحساب غير مفعل بعد، يرجى التواصل مع المدير للتفعيل.',
        ),
        backgroundColor: paid ? Colors.green : Colors.orange.shade800,
      ),
    );
  }

  Future<void> _showAddClassDialog() async {
    if (!_isPaid) {
      final uri = Uri.parse(
        '[https://wa.me/$](https://wa.me/$){AppConfig.adminWhatsApp}?text=${Uri.encodeComponent("السلام عليكم، أرغب في تفعيل اشتراكي السنوي في تطبيق سكرتير المدرسة. رقم هاتفي المسجل هو: ${widget.teacher['phone']}")}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    String selectedStage = educationLevels.keys.first;
    String selectedGrade = educationLevels[selectedStage]!.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final grades = educationLevels[selectedStage] ?? [];
            return AlertDialog(
              title: const Text('إضافة قسم دراسي'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStage,
                    decoration: const InputDecoration(
                      labelText: 'المرحلة الدراسية',
                      border: OutlineInputBorder(),
                    ),
                    items: educationLevels.keys
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setDialogState(() {
                        selectedStage = val;
                        selectedGrade = educationLevels[val]!.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'الفصل / القسم',
                      border: OutlineInputBorder(),
                    ),
                    items: grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setDialogState(() => selectedGrade = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await LocalAndCloudService.addClass({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'schoolId': widget.school['id'].toString(),
                      'stage': selectedStage,
                      'grade': selectedGrade,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadClasses();
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.school['name'] ?? 'الأقسام'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _checkingStatus ? null : _checkSubscriptionButton,
            icon: const Icon(Icons.sync),
            tooltip: 'تحديث حالة التفعيل',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        backgroundColor: _isPaid ? const Color(0xFF4A90E2) : Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: Icon(_isPaid ? Icons.add : Icons.lock_outline),
        label: Text(_isPaid ? 'إضافة قسم' : 'تفعيل الحساب لإضافة أقسام'),
      ),
      body: Column(
        children: [
          if (!_isPaid)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الحساب بانتظار التفعيل السنوي (${AppConfig.subscriptionPriceText})',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رقم هاتفك المسجل: ${widget.teacher['phone']} — تواصل مع المدير (${AppConfig.displayPhone}) لتفعيل حسابك فورا ثم اضغط زر التحديث بالأعلى.',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _classes.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد أقسام مضافة في هذه المدرسة حالياً.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = _classes[index];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: const Icon(Icons.class_, color: Color(0xFF4A90E2)),
                        title: Text(
                          '${c['grade']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('المرحلة: ${c['stage']}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
