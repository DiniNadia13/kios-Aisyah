import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kPrimary, width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintStyle: GoogleFonts.plusJakartaSans(
              color: kTextSecondary,
              fontSize: 13.5,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 8,
            shadowColor: Colors.black12,
            indicatorColor: kPrimaryLight,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Pesanan',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
