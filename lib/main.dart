
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import 'firebase_options.dart';
import 'helperFirebase/appRoute.dart';
import 'helperFirebase/bubble_custom.dart';
import 'helperFirebase/services_firebase.dart';


final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF2F3C7E);
    final surface = const Color(0xFFF7F7FB);

    final baseLight = ThemeData(
      useMaterial3: true,
      fontFamily: "almarai",
      colorScheme: ColorScheme.fromSeed(seedColor: seed, surface: surface),
      scaffoldBackgroundColor: surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );

    final baseDark = ThemeData(
      useMaterial3: true,
      fontFamily: "almarai",
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );

    return MaterialApp(
      title: "مشروع فايربيس المستخدمين",
      debugShowCheckedModeBanner: false,
      theme: baseLight,
      darkTheme: baseDark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale("ar","SA"),
      supportedLocales: const [Locale("ar","SA")],
      navigatorKey: navKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: Routes.splash,
    );
  }
}


class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final StreamSubscription<User?> _sub;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _sub = authService.auth$.listen((u) {
      final target = (u == null) ? Routes.signIn : Routes.dashboard;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        navKey.currentState?.pushNamedAndRemoveUntil(target, (_) => false);
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F3C7E), Color(0xFF4F8FC0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _spin,
                child: const Icon(Icons.bubble_chart, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('جارٍ التحميل...', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}


class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await authService.signIn(_email.text.trim(), _pass.text);
      if (!mounted) return;
      navKey.currentState?.pushNamedAndRemoveUntil(Routes.dashboard, (_) => false);
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? e.code);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundShapes(reverse: false,),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: cs.primaryContainer,
                          child: Icon(Icons.lock_open, color: cs.onPrimaryContainer, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text('أهلًا بك مجددًا', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                          validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريدًا إلكترونيًا صحيحًا' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'كلمة المرور'),
                          validator: (v) => (v == null || v.length < 6) ? '٦ أحرف على الأقل' : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _login,
                            child: _busy
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('تسجيل الدخول'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy ? null : () => navKey.currentState?.pushNamed(Routes.signUp),
                          child: const Text("مستخدم جديد؟ أنشئ حسابًا"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final cred = await authService.signUp(_email.text.trim(), _pass.text, _name.text.trim());
      await userRepo.createUserDoc(user: cred.user!, name: _name.text.trim());
      if (!mounted) return;
      navKey.currentState?.pushNamedAndRemoveUntil(Routes.dashboard, (_) => false);
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? e.code);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundShapes(reverse: false),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text('إنشاء حساب', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                          validator: (v) => (v == null || v.trim().length < 2) ? 'هذا الحقل مطلوب' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                          validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريدًا إلكترونيًا صحيحًا' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'كلمة المرور'),
                          validator: (v) => (v == null || v.length < 6) ? '٦ أحرف على الأقل' : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _register,
                            child: _busy
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('إنشاء الحساب'),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () => navKey.currentState?.pushNamed(Routes.signIn),
                          child: const Text("لديك حساب؟ تسجيل الدخول"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _index = 0;

  // التبويبات: مستخدمون + إعدادات
  final _tabs = const [
    UsersView(),     // ويدجت بدون Scaffold
    SettingsView(),  // ويدجت بدون Scaffold
  ];


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),



      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'المستخدمون',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}


class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final u = authService.current;
    return Scaffold(

      appBar: AppBar(
        centerTitle: false,
        title: const Text('المستخدمون'),
        actions: [
          if(u !=null)
            TextButton(
              onPressed: () async {
                await userRepo.touchLastSeen(u.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث آخر ظهور')),
                  );
                }
              },
              child: const Text('تحديث آخر ظهور'),
            )
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: userRepo.users$(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمون بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final name = (d['name'] ?? '') as String;
              final email = (d['email'] ?? '') as String;
              DateTime? toDt(dynamic v) => v is Timestamp ? v.toDate() : null;
              final created = toDt(d['createdAt']);
              String dateStr(DateTime? x) => x == null
                  ? '—'
                  : '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                color: Colors.teal,
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(name.isEmpty ? 'بدون اسم' : name,style: TextStyle(color: Colors.white),),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email.isEmpty ? '—' : email,style: TextStyle(color: Colors.white),),
                      Text('تم الانشاء في: ${dateStr(created)}', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white)),
                    ],
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

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد تسجيل الخروج من الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await authService.signOut();
      if (context.mounted) {
        navKey.currentState?.pushNamedAndRemoveUntil(Routes.signIn, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = authService.current;
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // هيدر متدرّج مع بيانات سريعة
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  cs.primary,
                  cs.primary.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.onPrimary.withValues(alpha:0.15),
                  child: Icon(Icons.person, color: cs.onPrimary, size: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultTextStyle(
                    style: TextStyle(color: cs.onPrimary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u?.displayName?.isNotEmpty == true ? u!.displayName! : 'مستخدم',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u?.email ?? '—',
                          style: TextStyle(color: cs.onPrimary.withValues(alpha:0.85)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, size: 18, color: cs.onPrimary),
                      const SizedBox(width: 6),
                      Text('حسابي', style: TextStyle(color: cs.onPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // مسافة صغيرة تحت الهيدر
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // بطاقة الحساب
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'حساب',
            subtitle: 'معلومات الحساب والإجراءات',
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('الاسم'),
                subtitle: Text(u?.displayName ?? '—'),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('البريد الإلكتروني'),
                subtitle: Text(u?.email ?? '—'),
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'التفضيلات',
            subtitle: 'خيارات الواجهة والتطبيق',
            children: [
              ListTile(
                leading: const Icon(Icons.translate_outlined),
                title: const Text('اللغة'),
                subtitle: const Text('العربية'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  // لاحقًا: فتحة اختيار اللغة
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اللغة الحالية: العربية')),
                  );
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: const Text('المظهر'),
                subtitle: const Text('يتبع ثيم النظام'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يتم التحكم بالمظهر من إعدادات النظام/التطبيق')),
                  );
                },
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}


class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: cs.surfaceContainerHighest.withValues(alpha:0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha:0.8),
                      )),
                ],
              ),
            ),
            const Divider(height: 0),

            ...children,
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}






