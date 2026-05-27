import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router/app_router.dart';
import 'core/constants/google_auth_constants.dart';
import 'core/constants/stripe_constants.dart';
import 'core/di/injection.dart';
import 'core/delivery/guest_delivery_location_repository.dart';
import 'core/delivery/presentation/guest_delivery_cubit.dart';
import 'core/network/dio_client.dart';
import 'core/region/currency_scope.dart';
import 'core/region/region_repository.dart';
import 'core/region/presentation/region_bloc.dart';
import 'features/config/domain/entities/site_config.dart';
import 'features/config/utils/config_theme_builder.dart';
import 'features/auth/domain/usecases/complete_login_otp_usecase.dart';
import 'features/auth/domain/usecases/get_me_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/login_with_google_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'core/locale/app_locale.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/product/domain/usecases/get_categories_usecase.dart';
import 'features/product/domain/usecases/get_featured_products_usecase.dart';
import 'features/product/domain/usecases/get_new_arrivals_usecase.dart';
import 'features/product/domain/usecases/get_on_sale_products_usecase.dart';
import 'features/product/domain/usecases/get_product_list_usecase.dart';
import 'features/product/presentation/bloc/category_list_bloc.dart';
import 'features/product/presentation/bloc/product_list_bloc.dart';
import 'features/cart/data/datasources/cart_local_datasource.dart';
import 'features/cart/domain/usecases/cart_usecases.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/wishlist/domain/usecases/wishlist_usecases.dart';
import 'features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'features/order/domain/usecases/order_usecases.dart';
import 'features/order/presentation/bloc/order_list_bloc.dart';
import 'features/address/domain/usecases/address_usecases.dart';
import 'features/config/domain/usecases/get_site_config_usecase.dart';
import 'features/config/presentation/bloc/config_bloc.dart';
import 'features/address/presentation/bloc/address_list_bloc.dart';
import 'features/video/domain/usecases/get_inspiration_videos_usecase.dart';
import 'features/video/presentation/bloc/inspiration_videos_bloc.dart';
import 'core/notifications/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/app.env', isOptional: true);
  await loadStripePublishableKeyFromAssets();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (kDebugMode) debugPrint('[Firebase] initializeApp skipped: $e');
  }

  if (kStripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = kStripePublishableKey;
    await Stripe.instance.applySettings();
  } else if (kDebugMode) {
    debugPrint(
      '[Stripe] Card/UPI disabled: put pk_… in assets/env/app.env as VITE_STRIPE_PUBLISHABLE_KEY=… '
      '(same as web), then full restart — or run with '
      '--dart-define=VITE_STRIPE_PUBLISHABLE_KEY=pk_test_…',
    );
  }

  await initInjection();
  await loadSavedAppLocale(sl<SharedPreferences>());

  final googleWebClientId = resolveGoogleWebClientId();
  final googleIosClientId = resolveGoogleIosClientId();
  final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  if (kDebugMode) {
    if (googleWebClientId.isEmpty) {
      debugPrint(
        '[GoogleSignIn] Missing GOOGLE_WEB_CLIENT_ID. Set in assets/env/app.env or '
        '--dart-define=GOOGLE_WEB_CLIENT_ID=... (same as backend GOOGLE_CLIENT_ID). '
        'Without it, Android cannot return an id token.',
      );
    }
    if (isIos && googleIosClientId.isEmpty) {
      debugPrint(
        '[GoogleSignIn] Missing GOOGLE_IOS_CLIENT_ID. Create an iOS OAuth client in Google Cloud '
        'for this bundle id, then set GOOGLE_IOS_CLIENT_ID in app.env or --dart-define.',
      );
    }
  }
  await GoogleSignIn.instance.initialize(
    clientId: isIos && googleIosClientId.isNotEmpty ? googleIosClientId : null,
    serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
  );
  runApp(const RlocoApp());
}

final GoRouter _appRouter = createAppRouter();

class RlocoApp extends StatelessWidget {
  const RlocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            loginUseCase: sl<LoginUseCase>(),
            completeLoginOtpUseCase: sl<CompleteLoginOtpUseCase>(),
            loginWithGoogleUseCase: sl<LoginWithGoogleUseCase>(),
            registerUseCase: sl<RegisterUseCase>(),
            logoutUseCase: sl<LogoutUseCase>(),
            getMeUseCase: sl<GetMeUseCase>(),
          )..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => ProductListBloc(
            getProductListUseCase: sl<GetProductListUseCase>(),
            getFeaturedProductsUseCase: sl<GetFeaturedProductsUseCase>(),
            getNewArrivalsUseCase: sl<GetNewArrivalsUseCase>(),
            getOnSaleProductsUseCase: sl<GetOnSaleProductsUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => CategoryListBloc(
            getCategoriesUseCase: sl<GetCategoriesUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => CartBloc(
            getCartUseCase: sl<GetCartUseCase>(),
            addCartItemUseCase: sl<AddCartItemUseCase>(),
            updateCartItemUseCase: sl<UpdateCartItemUseCase>(),
            removeCartItemUseCase: sl<RemoveCartItemUseCase>(),
            clearCartUseCase: sl<ClearCartUseCase>(),
            dioClient: sl<DioClient>(),
            localCart: sl<CartLocalDataSource>(),
          ),
        ),
        BlocProvider(
          create: (context) => WishlistBloc(
            getWishlistUseCase: sl<GetWishlistUseCase>(),
            addWishlistItemUseCase: sl<AddWishlistItemUseCase>(),
            removeWishlistItemUseCase: sl<RemoveWishlistItemUseCase>(),
            dioClient: sl<DioClient>(),
          ),
        ),
        BlocProvider(
          create: (context) => OrderListBloc(
            getOrdersUseCase: sl<GetOrdersUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => AddressListBloc(
            listAddressesUseCase: sl<ListAddressesUseCase>(),
            deleteAddressUseCase: sl<DeleteAddressUseCase>(),
            setDefaultAddressUseCase: sl<SetDefaultAddressUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => InspirationVideosBloc(
            getInspirationVideosUseCase: sl<GetInspirationVideosUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => ConfigBloc(sl<GetSiteConfigUseCase>())
            ..add(const ConfigLoadRequested()),
        ),
        BlocProvider(
          create: (context) => RegionBloc(
            regionRepository: sl<RegionRepository>(),
            initialRegion: sl<RegionRepository>().getRegionSync(),
          ),
        ),
        BlocProvider(
          create: (context) => GuestDeliveryCubit(
            sl<GuestDeliveryLocationRepository>(),
          ),
        ),
      ],
      child: BlocBuilder<RegionBloc, RegionState>(
        builder: (context, state) => CurrencyScope(
          region: state.region,
          child: _AppLifecycleHandler(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  context.read<CartBloc>().add(const CartMergeGuestCartRequested());
                  context.read<WishlistBloc>().add(const WishlistMergeGuestRequested());
                  context.read<AddressListBloc>().add(const AddressListLoadRequested());
                  sl<FCMService>().init();
                } else if (state is AuthUnauthenticated) {
                  context.read<AddressListBloc>().add(const AddressListReset());
                }
              },
              child: BlocBuilder<ConfigBloc, ConfigState>(
                buildWhen: (a, b) => b is ConfigLoaded,
                builder: (context, state) {
                  final config = state is ConfigLoaded ? state.config : SiteConfig.defaultConfig;
                  final theme = ConfigThemeBuilder.build(config.design);
                  return ValueListenableBuilder<Locale>(
                    valueListenable: appLocale,
                    builder: (context, loc, _) {
                      return MaterialApp.router(
                        title: config.general.siteName,
                        theme: theme,
                        routerConfig: _appRouter,
                        locale: loc,
                        supportedLocales: const [Locale('en'), Locale('hi')],
                        localizationsDelegates: const [
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// When app resumes from background, re-check auth from stored token so session is restored.
/// Also refreshes site config on resume and every 30 seconds (matching web app behavior).
class _AppLifecycleHandler extends StatefulWidget {
  const _AppLifecycleHandler({required this.child});
  final Widget child;

  @override
  State<_AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<_AppLifecycleHandler>
    with WidgetsBindingObserver {
  Timer? _configRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startConfigRefreshTimer();
  }

  @override
  void dispose() {
    _configRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startConfigRefreshTimer() {
    _configRefreshTimer?.cancel();
    _configRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<ConfigBloc>().add(const ConfigLoadRequested());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    final authBloc = context.read<AuthBloc>();
    if (authBloc.shouldTryRestoreFromToken) {
      authBloc.add(const AuthCheckRequested());
    }
    context.read<ConfigBloc>().add(const ConfigLoadRequested());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
