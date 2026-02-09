import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_edit_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/account_page.dart';
import '../../features/home/presentation/pages/add_payment_method_page.dart';
import '../../features/home/presentation/pages/about_page.dart';
import '../../features/home/presentation/pages/change_password_page.dart';
import '../../features/home/presentation/pages/contact_page.dart';
import '../../features/home/presentation/pages/coupons_page.dart';
import '../../features/home/presentation/pages/delivery_location_page.dart';
import '../../features/home/presentation/pages/language_page.dart';
import '../../features/home/presentation/pages/notifications_page.dart';
import '../../features/home/presentation/pages/payment_methods_page.dart';
import '../../features/home/presentation/pages/returns_page.dart';
import '../../features/home/presentation/pages/rewards_page.dart';
import '../../features/home/presentation/pages/reviews_page.dart';
import '../../features/home/presentation/pages/shipping_info_page.dart';
import '../../features/home/presentation/pages/settings_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product/presentation/bloc/product_list_bloc.dart';
import '../../features/product/presentation/pages/categories_page.dart';
import '../../features/product/presentation/pages/category_products_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/search_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../features/order/domain/usecases/order_usecases.dart';
import '../../features/order/presentation/bloc/order_detail_bloc.dart';
import '../../features/order/presentation/bloc/order_list_bloc.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/orders_page.dart';
import '../../features/address/presentation/pages/address_form_page.dart';
import '../../features/address/presentation/pages/addresses_page.dart';
import '../../features/order/presentation/pages/checkout_page.dart';
import '../../features/order/presentation/pages/order_confirmation_page.dart';
import '../../features/home/presentation/pages/not_found_page.dart';
import '../../features/home/presentation/pages/static_content_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';

final GlobalKey<NavigatorState> _rootNavKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginPage(redirectAfterLogin: state.extra as String?),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/category/:gender/:slug',
        builder: (context, state) {
          final gender = state.pathParameters['gender'] ?? '';
          final slug = state.pathParameters['slug'] ?? '';
          return CategoryProductsPage(gender: gender, slug: slug);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/all-products',
        builder: (context, state) => ProductListPage(
          title: 'All Products',
          loadEvent: const ProductListLoadRequested(limit: 50),
        ),
      ),
      GoRoute(
        path: '/new-arrivals',
        builder: (context, state) => ProductListPage(
          title: 'New Arrivals',
          loadEvent: const ProductListLoadNewArrivals(limit: 50),
        ),
      ),
      GoRoute(
        path: '/sale',
        builder: (context, state) => ProductListPage(
          title: 'On Sale',
          loadEvent: const ProductListLoadOnSale(limit: 50),
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProductDetailPage(productId: id);
        },
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditPage(),
      ),
      GoRoute(
        path: '/payment-methods',
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        path: '/add-payment-method',
        builder: (context, state) => const AddPaymentMethodPage(),
      ),
      GoRoute(
        path: '/delivery-location',
        builder: (context, state) => const DeliveryLocationPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsPage(),
      ),
      GoRoute(
        path: '/coupons',
        builder: (context, state) => const CouponsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguagePage(),
      ),
      GoRoute(
        path: '/reviews',
        builder: (context, state) => const ReviewsPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BlocProvider(
            create: (context) => OrderDetailBloc(
              getOrderByIdUseCase: sl<GetOrderByIdUseCase>(),
              getOrderTrackingUseCase: sl<GetOrderTrackingUseCase>(),
              cancelOrderUseCase: sl<CancelOrderUseCase>(),
            )..add(OrderDetailLoadRequested(id)),
            child: OrderDetailPage(orderId: id),
          );
        },
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesPage(),
      ),
      GoRoute(
        path: '/addresses/add',
        builder: (context, state) => const AddressFormPage(),
      ),
      GoRoute(
        path: '/addresses/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AddressFormPage(addressId: id);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/order-confirmation/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderConfirmationPage(orderId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistPage(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const StaticContentPage(title: 'Help Center'),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const StaticContentPage(title: 'Terms of Service'),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const StaticContentPage(title: 'Privacy Policy'),
      ),
      GoRoute(
        path: '/size-guide',
        builder: (context, state) => const StaticContentPage(title: 'Size Guide'),
      ),
      GoRoute(
        path: '/shipping',
        builder: (context, state) => const ShippingInfoPage(),
      ),
      GoRoute(
        path: '/returns',
        builder: (context, state) => const ReturnsPage(),
      ),
    ],
  );
}
