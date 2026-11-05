import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'admin_notifier.dart';
import 'state.dart';
import 'ui/auth_screen.dart';
import 'ui/cart_screen.dart';
import 'ui/catalog_screen.dart';
import 'ui/common.dart';
import 'ui/home_screen.dart';
import 'ui/orders_screen.dart';
import 'ui/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KiosAisyhaApp());
}

class KiosAisyhaApp extends StatelessWidget {
  const KiosAisyhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..load()),
        ChangeNotifierProvider(create: (_) => CartState()..loadSettings()),
        ChangeNotifierProvider(create: (_) => OrdersState()),
      ],
      child: MaterialApp(
        title: 'Kios Aisyha',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: kBg,
          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimary,
            primary: kPrimary,
            surface: kSurface,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: kSurface,
            foregroundColor: kTextPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
            centerTitle: false,
            titleTextStyle: GoogleFonts.plusJakartaSans(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 3,
            shadowColor: const Color(0x14059669),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: const Color(0x4D047857),
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEDF2F7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEDF2F7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kPrimary, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintStyle: GoogleFonts.plusJakartaSans(
              color: kTextSecondary,
              fontSize: 13.5,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 12,
            shadowColor: const Color(0x1F000000),
            indicatorColor: const Color(0xFFE6F4EA),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? kPrimaryDark : kTextSecondary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected ? kPrimaryDark : kTextSecondary,
                size: 23,
              );
            }),
          ),
        ),
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  static void switchTab(BuildContext context, int tabIndex) {
    context.findAncestorStateOfType<_ShellState>()?.setIndex(tabIndex);
  }

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthState>();
        AdminNotifier.instance.start(context, loggedIn: auth.loggedIn, isAdmin: auth.isAdmin);
      }
    });
  }

  @override
  void dispose() {
    AdminNotifier.instance.stop();
    super.dispose();
  }

  void setIndex(int i) {
    if (i == 3) {
      context.read<OrdersState>().load();
    }
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final auth = context.watch<AuthState>();
    AdminNotifier.instance.start(context, loggedIn: auth.loggedIn, isAdmin: auth.isAdmin);

    Widget needLogin(Widget child) => auth.loggedIn
        ? child
        : Scaffold(
            appBar: AppBar(title: const Text('Pesanan Saya')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, size: 48, color: kPrimaryDark),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pantau Pesanan Anda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk untuk melacak belanjaan dan riwayat pembelian sembako Anda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Masuk / Daftar Sekarang'),
                    ),
                  ],
                ),
              ),
            ),
          );

    final pages = [
      const HomeScreen(),
      const CatalogScreen(),
      const CartScreen(),
      needLogin(OrdersScreen(key: ValueKey(auth.loggedIn))),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: index,
          height: 66,
          onDestinationSelected: setIndex,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Katalog',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cart.count > 0,
                backgroundColor: kSecondary,
                label: Text(
                  '${cart.count}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cart.count > 0,
                backgroundColor: kSecondary,
                label: Text(
                  '${cart.count}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                child: const Icon(Icons.shopping_bag_rounded),
              ),
              label: 'Keranjang',
            ),
            NavigationDestination(
              icon: ListenableBuilder(
                listenable: AdminNotifier.instance,
                builder: (_, __) {
                  final count = AdminNotifier.instance.userActiveOrderCount;
                  final showBadge = !auth.isAdmin && auth.loggedIn && count > 0;
                  return Badge(
                    isLabelVisible: showBadge,
                    backgroundColor: const Color(0xFF0284C7),
                    label: Text(
                      '$count',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    child: const Icon(Icons.receipt_long_outlined),
                  );
                },
              ),
              selectedIcon: ListenableBuilder(
                listenable: AdminNotifier.instance,
                builder: (_, __) {
                  final count = AdminNotifier.instance.userActiveOrderCount;
                  final showBadge = !auth.isAdmin && auth.loggedIn && count > 0;
                  return Badge(
                    isLabelVisible: showBadge,
                    backgroundColor: const Color(0xFF0284C7),
                    label: Text(
                      '$count',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded),
                  );
                },
              ),
              label: 'Pesanan',
            ),
            NavigationDestination(
              icon: ListenableBuilder(
                listenable: AdminNotifier.instance,
                builder: (_, __) {
                  final showBadge = auth.isAdmin && AdminNotifier.instance.pendingCount > 0;
                  return Badge(
                    isLabelVisible: showBadge,
                    backgroundColor: const Color(0xFFEF4444),
                    label: Text(
                      '${AdminNotifier.instance.pendingCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    child: const Icon(Icons.person_outline_rounded),
                  );
                },
              ),
              selectedIcon: ListenableBuilder(
                listenable: AdminNotifier.instance,
                builder: (_, __) {
                  final showBadge = auth.isAdmin && AdminNotifier.instance.pendingCount > 0;
                  return Badge(
                    isLabelVisible: showBadge,
                    backgroundColor: const Color(0xFFEF4444),
                    label: Text(
                      '${AdminNotifier.instance.pendingCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    child: const Icon(Icons.person_rounded),
                  );
                },
              ),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
