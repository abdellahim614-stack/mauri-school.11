import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AdminControlApp());
}

class AdminControlApp extends StatelessWidget {
  const AdminControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لوحة تحكم المدير - تفعيل المعلمين',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        scaffoldBackgroundColor: const Color(0xFFF2F4F8),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const String databaseUrl =
      'https://mauri-school-6d5f1-default-rtdb.firebaseio.com';

  final TextEditingController _searchPhoneController = TextEditingController();
  bool _loading = false;
  Map<String, Map<String, dynamic>> _teachers = {};

  @override
  void initState() {
    super.initState();
    _fetchAllTeachers();
  }

  Future<void> _fetchAllTeachers() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('$databaseUrl/teachers.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body != 'null') {
        final rawMap = jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, Map<String, dynamic>> parsed = {};
        rawMap.forEach((key, value) {
          if (value is Map) {
            parsed[key] = Map<String, dynamic>.from(value);
          }
        });
        setState(() {
          _teachers = parsed;
        });
      } else {
        setState(() => _teachers = {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تأكد من الاتصال بالإنترنت لتحديث القائمة'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleTeacherActivation(String phone, bool newStatus) async {
    try {
      final url = Uri.parse('$databaseUrl/teachers/$phone.json');
      final response = await http.patch(
        url,
        body: jsonEncode({
          'isPaid': newStatus,
          'activatedAt': newStatus ? DateTime.now().toIso8601String() : null,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _teachers[phone]?['isPaid'] = newStatus;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'تم تفعيل الاشتراك السنوي (200 أوقية) للمعلم $phone بنجاح!'
                  : 'تم إلغاء تفعيل المعلم $phone',
            ),
            backgroundColor:
                newStatus ? const Color(0xFF2E7D32) : Colors.orange.shade800,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء الاتصال بالخادم'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _activateByPhoneDirectly() async {
    final phone = _searchPhoneController.text.trim().replaceAll(' ', '');
    if (phone.isEmpty) return;

    await _toggleTeacherActivation(phone, true);
    _fetchAllTeachers();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchPhoneController.text.trim();
    final entries = _teachers.entries.where((e) {
      if (query.isEmpty) return true;
      final phone = e.key;
      final name = e.value['name']?.toString() ?? '';
      return phone.contains(query) || name.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'لوحة المدير - تفعيل المعلمين',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث القائمة',
            onPressed: _fetchAllTeachers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفعيل سريع برقم هاتف المعلم (200 أوقية للسنة):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchPhoneController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'ابحث برقم الهاتف أو اسم المعلم...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _activateByPhoneDirectly,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('تفعيل الرقم'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : entries.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد حسابات معلمين مسجلة حالياً.\nعندما ينشئ أي معلم حسابه سيظهر رقمه واسمه هنا مباشرة.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final phone = entries[index].key;
                            final data = entries[index].value;
                            final name = data['name']?.toString() ?? 'معلم';
                            final password = data['password']?.toString() ?? '';
                            final isPaid = data['isPaid'] == true;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isPaid
                                      ? const Color(0xFF81C784)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'رقم الهاتف: $phone  |  كلمة السر: $password',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: isPaid,
                                    activeColor: const Color(0xFF2E7D32),
                                    onChanged: (val) =>
                                        _toggleTeacherActivation(phone, val),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
