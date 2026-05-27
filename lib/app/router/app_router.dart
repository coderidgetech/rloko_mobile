import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/models/login_otp_route_extra.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_otp_verification_page.dart';
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
import '../../features/rewards/presentation/pages/rewards_page.dart';
import '../../features/home/presentation/pages/reviews_page.dart';
import '../../features/home/presentation/pages/shipping_info_page.dart';
import '../../features/home/presentation/pages/settings_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product/presentation/bloc/product_list_bloc.dart';
import '../../features/product/presentation/pages/categories_page.dart';
import '../../features/product/presentation/pages/category_products_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/widgets/sort_bottom_sheet.dart';
import '../../features/product/presentation/pages/search_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../features/order/domain/usecases/order_usecases.dart';
import '../../features/return_order/domain/usecases/create_return_usecase.dart';
import '../../features/order/presentation/bloc/order_detail_bloc.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/order_tracking_page.dart';
import '../../features/order/presentation/pages/orders_page.dart';
import '../../features/order/presentation/pages/checkout_page.dart';
import '../../features/address/presentation/pages/address_form_page.dart';
import '../../features/address/presentation/pages/addresses_page.dart';
import '../../features/order/presentation/pages/order_confirmation_page.dart';
import '../../features/home/presentation/pages/help_center_page.dart';
import '../../features/home/presentation/pages/not_found_page.dart';
import '../../features/home/presentation/pages/privacy_page.dart';
import '../../features/home/presentation/pages/size_guide_page.dart';
import '../../features/home/presentation/pages/terms_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/review/presentation/pages/write_review_page.dart';
import '../../features/video/presentation/pages/video_player_page.dart';
import '../../features/order/presentation/pages/guest_checkout_page.dart';

final GlobalKey<NavigatorState> _rootNavKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      // Redirects for web/shared-link path parity (avoid "page not found")
      GoRoute(
        path: '/order/:id',
        redirect: (_, state) => '/orders/${state.pathParameters['id'] ?? ''}',
      ),
      GoRoute(
        path: '/add-address',
        redirect: (_, __) => '/addresses/add',
      ),
      GoRoute(
        path: '/payment',
        redirect: (_, __) => '/cart',
      ),
      GoRoute(
        path: '/featured-collection',
        redirect: (_, __) => '/all-products',
      ),
      GoRoute(
        path: '/gift-for-her',
        redirect: (_, __) => '/category/women?gift=true',
      ),
      GoRoute(
        path: '/gift-for-him',
        redirect: (_, __) => '/category/men?gift=true',
      ),
      GoRoute(
        path: '/otp-verification',
        redirect: (context, state) {
          if (state.extra is! LoginOtpRouteExtra) return '/login';
          return null;
        },
        builder: (context, state) {
          final extra = state.extra! as LoginOtpRouteExtra;
          return LoginOtpVerificationPage(
            phone: extra.phone,
            returnTo: extra.returnTo,
          );
        },
      ),
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
          final isGift = state.uri.queryParameters['gift'] == 'true';
          return CategoryProductsPage(
            gender: gender,
            slug: slug,
            isGiftMode: isGift,
          );
        },
      ),
      GoRoute(
        path: '/category/:gender',
        builder: (context, state) {
          final gender = state.pathParameters['gender'] ?? '';
          final isGift = state.uri.queryParameters['gift'] == 'true';
          return CategoryProductsPage(
            gender: gender,
            slug: '',
            isGiftMode: isGift,
          );
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
          loadEvent: const ProductListLoadRequested(limit: 200),
          sortOptions: const [
            SortOption(value: 'featured', label: 'Featured'),
            SortOption(value: 'newest', label: 'Newest'),
            SortOption(value: 'price-low', label: 'Price: Low to High'),
            SortOption(value: 'price-high', label: 'Price: High to Low'),
          ],
          initialSort: 'featured',
          statsLabel: 'Showing %d products',
        ),
      ),
      GoRoute(
        path: '/new-arrivals',
        builder: (context, state) => ProductListPage(
          title: 'New Arrivals',
          loadEvent: const ProductListLoadNewArrivals(limit: 200),
          filterPills: const [
            FilterPill(value: 'all', label: 'All'),
            FilterPill(value: 'dresses', label: 'Dresses'),
            FilterPill(value: 'tops', label: 'Tops'),
            FilterPill(value: 'bags', label: 'Bags'),
            FilterPill(value: 'shoes', label: 'Shoes'),
          ],
          statsLabel: '%d new items this week',
          emptyTitle: 'No new arrivals',
        ),
      ),
      GoRoute(
        path: '/sale',
        builder: (context, state) => ProductListPage(
          title: 'On Sale',
          loadEvent: const ProductListLoadOnSale(limit: 200),
          sortOptions: const [
            SortOption(value: 'discount', label: 'Highest Discount'),
            SortOption(value: 'price-low', label: 'Price: Low to High'),
            SortOption(value: 'price-high', label: 'Price: High to Low'),
          ],
          initialSort: 'discount',
          showSaleBanner: true,
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
        path: '/reviews/write/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          final productName = state.uri.queryParameters['name'];
          return WriteReviewPage(productId: productId, productName: productName);
        },
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
              createReturnUseCase: sl<CreateReturnUseCase>(),
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
        builder: (context, state) {
          final e = state.extra;
          final pm = e is String && (e == 'card' || e == 'upi' || e == 'cod')
              ? e
              : null;
          return CheckoutPage(initialPaymentMethod: pm);
        },
      ),
      GoRoute(
        path: '/checkout/guest',
        builder: (context, state) => const GuestCheckoutPage(),
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
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/size-guide',
        builder: (context, state) => const SizeGuidePage(),
      ),
      GoRoute(
        path: '/tracking/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/shipping',
        builder: (context, state) => const ShippingInfoPage(),
      ),
      GoRoute(
        path: '/returns',
        builder: (context, state) => const ReturnsPage(),
      ),
      GoRoute(
        path: '/video/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VideoPlayerPage(
            videoUrl: extra?['videoUrl'] as String? ?? '',
            title: extra?['title'] as String? ?? '',
            category: extra?['category'] as String? ?? '',
            thumbnailUrl: extra?['thumbnailUrl'] as String?,
          );
        },
      ),
    ],
  );
}
