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
      'https://mauri-school-6d5f1-default-rtdb.firebaseio.com';
}

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
      theme:
