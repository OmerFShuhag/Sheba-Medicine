import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/medicine_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/order_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';

import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/widgets/cart_screen.dart';
import 'features/home/presentation/widgets/checkout_screen.dart';
import 'features/home/presentation/widgets/medicine_detail_screen.dart';
import 'features/home/presentation/widgets/orders_screen.dart';
import 'features/home/presentation/widgets/profile_screen.dart';

void main() {
  runApp(const ShebaMedicineApp());
}

class ShebaMedicineApp extends StatelessWidget {
  const ShebaMedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Sheba Medicine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/': (context) => Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return authProvider.isAuthenticated
                  ? const HomeScreen()
                  : const LoginScreen();
            },
          ),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/medicine': (context) => const HomeScreen(),
          

          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name?.startsWith('/medicine/') == true) {
            final id = int.tryParse(settings.name!.split('/').last);
            if (id != null) {
              return MaterialPageRoute(
                builder: (context) {
                  final medicineProvider = Provider.of<MedicineProvider>(
                    context,
                    listen: false,
                  );
                  final medicine = medicineProvider.medicines.firstWhere(
                    (m) => m.id == id,
                    orElse: () => throw Exception('Medicine not found'),
                  );
                  return MedicineDetailScreen(medicine: medicine);
                },
              );
            }
          }
          return null;
        },
      ),
    );
  }
}
