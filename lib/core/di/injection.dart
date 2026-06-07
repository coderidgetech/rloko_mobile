import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/base_url_resolver.dart';
import '../network/dio_client.dart';
import '../region/region_repository.dart';
import '../region/region_repository_impl.dart';
import '../delivery/guest_delivery_location_repository.dart';
import '../delivery/guest_delivery_location_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/complete_login_otp_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/get_me_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/login_with_google_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/send_login_otp_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/product/data/datasources/category_remote_datasource.dart';
import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/repositories/category_repository_impl.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/category_repository.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/get_categories_usecase.dart';
import '../../features/product/domain/usecases/get_featured_products_usecase.dart';
import '../../features/product/domain/usecases/get_new_arrivals_usecase.dart';
import '../../features/product/domain/usecases/get_on_sale_products_usecase.dart';
import '../../features/product/domain/usecases/get_product_by_id_usecase.dart';
import '../../features/product/domain/usecases/get_product_list_usecase.dart';
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import '../../features/cart/data/datasources/cart_remote_datasource.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/cart_usecases.dart';
import '../../features/wishlist/data/datasources/wishlist_local_datasource.dart';
import '../../features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import '../../features/wishlist/data/repositories/wishlist_repository_impl.dart';
import '../../features/wishlist/domain/repositories/wishlist_repository.dart';
import '../../features/wishlist/domain/usecases/wishlist_usecases.dart';
import '../../features/order/data/datasources/order_remote_datasource.dart';
import '../../features/order/data/repositories/order_repository_impl.dart';
import '../../features/order/domain/repositories/order_repository.dart';
import '../../features/order/domain/usecases/order_usecases.dart';
import '../../features/address/data/datasources/address_remote_datasource.dart';
import '../../features/address/data/repositories/address_repository_impl.dart';
import '../../features/address/domain/repositories/address_repository.dart';
import '../../features/address/domain/usecases/address_usecases.dart';
import '../../features/video/data/datasources/video_remote_datasource.dart';
import '../../features/video/data/repositories/video_repository_impl.dart';
import '../../features/video/domain/repositories/video_repository.dart';
import '../../features/video/domain/usecases/get_inspiration_videos_usecase.dart';
import '../../features/promotion/data/datasources/promotion_remote_datasource.dart';
import '../../features/promotion/data/repositories/promotion_repository_impl.dart';
import '../../features/promotion/domain/repositories/promotion_repository.dart';
import '../../features/promotion/domain/usecases/get_promotions_usecase.dart';
import '../../features/promotion/domain/usecases/validate_promotion_usecase.dart';
import '../../features/return_order/data/datasources/return_remote_datasource.dart';
import '../../features/return_order/data/repositories/return_repository_impl.dart';
import '../../features/return_order/domain/repositories/return_repository.dart';
import '../../features/return_order/domain/usecases/create_return_usecase.dart';
import '../../features/return_order/domain/usecases/list_returns_usecase.dart';
import '../../features/shipping/data/datasources/shipping_remote_datasource.dart';
import '../../features/shipping/data/repositories/shipping_repository_impl.dart';
import '../../features/shipping/domain/repositories/shipping_repository.dart';
import '../../features/config/data/datasources/config_remote_datasource.dart';
import '../../features/config/data/repositories/config_repository_impl.dart';
import '../../features/config/domain/repositories/config_repository.dart';
import '../../features/config/domain/usecases/get_site_config_usecase.dart';
import '../../features/shipping/domain/usecases/calculate_shipping_usecase.dart';
import '../../features/shipping/domain/usecases/get_shipping_methods_usecase.dart';
import '../../features/tax/data/datasources/tax_remote_datasource.dart';
import '../../features/tax/data/repositories/tax_repository_impl.dart';
import '../../features/tax/domain/repositories/tax_repository.dart';
import '../../features/tax/domain/usecases/calculate_tax_usecase.dart';
import '../../features/payment/data/datasources/payment_remote_datasource.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/create_payment_intent_usecase.dart';
import '../../features/rewards/data/datasources/rewards_remote_datasource.dart';
import '../../features/rewards/data/repositories/rewards_repository_impl.dart';
import '../../features/rewards/domain/repositories/rewards_repository.dart';
import '../../features/rewards/domain/usecases/get_rewards_summary_usecase.dart';
import '../../features/rewards/domain/usecases/get_rewards_transactions_usecase.dart';
import '../../features/rewards/domain/usecases/redeem_rewards_usecase.dart';
import '../../features/review/data/datasources/review_remote_datasource.dart';
import '../../features/review/data/repositories/review_repository_impl.dart';
import '../../features/review/domain/repositories/review_repository.dart';
import '../../features/review/domain/usecases/get_my_reviews_usecase.dart';
import '../../features/review/domain/usecases/get_product_reviews_usecase.dart';
import '../../features/review/domain/usecases/submit_review_usecase.dart';
import '../../features/product/data/datasources/product_local_datasource.dart';
import '../../features/product/domain/usecases/get_recommendations_usecase.dart';
import '../notifications/fcm_service.dart';
import '../../features/order/presentation/bloc/checkout_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initInjection() async {
  // Log API base URL in debug so user can verify
  if (kDebugMode) {
    final url = resolveApiBaseUrl();
    debugPrint('Rloko API base URL: $url');
  }
  // Core
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<DioClient>(() => DioClient(sharedPreferences: prefs));
  sl.registerLazySingleton<RegionRepository>(
    () => RegionRepositoryImpl(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<GuestDeliveryLocationRepository>(
    () => GuestDeliveryLocationRepositoryImpl(sl<SharedPreferences>()),
  );

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<DioClient>()),
  );
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SendLoginOtpUseCase>(
    () => SendLoginOtpUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<CompleteLoginOtpUseCase>(
    () => CompleteLoginOtpUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LoginWithGoogleUseCase>(
    () => LoginWithGoogleUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetMeUseCase>(
    () => GetMeUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ChangePasswordUseCase>(
    () => ChangePasswordUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(sl<AuthRepository>()),
  );

  // Product
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(sl<DioClient>(), sl<RegionRepository>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl<ProductRemoteDataSource>(), sl<ProductLocalDataSource>()),
  );
  sl.registerLazySingleton<GetProductListUseCase>(
    () => GetProductListUseCase(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<GetProductByIdUseCase>(
    () => GetProductByIdUseCase(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<GetFeaturedProductsUseCase>(
    () => GetFeaturedProductsUseCase(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<GetNewArrivalsUseCase>(
    () => GetNewArrivalsUseCase(sl<ProductRepository>()),
  );
  sl.registerLazySingleton<GetOnSaleProductsUseCase>(
    () => GetOnSaleProductsUseCase(sl<ProductRepository>()),
  );

  // Config (site config for hero, etc.)
  sl.registerLazySingleton<ConfigRemoteDataSource>(
    () => ConfigRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<ConfigRepository>(
    () => ConfigRepositoryImpl(sl<ConfigRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetSiteConfigUseCase>(
    () => GetSiteConfigUseCase(sl<ConfigRepository>()),
  );

  // Category
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl<CategoryRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(sl<CategoryRepository>()),
  );

  // Cart
  // CartLocalDataSource is intentionally wired to CartBloc directly (not via CartRepositoryImpl).
  // It handles guest-cart storage at the BLoC layer; CartRepositoryImpl is remote-only.
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSource(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(sl<CartRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetCartUseCase>(
    () => GetCartUseCase(sl<CartRepository>()),
  );
  sl.registerLazySingleton<AddCartItemUseCase>(
    () => AddCartItemUseCase(sl<CartRepository>()),
  );
  sl.registerLazySingleton<UpdateCartItemUseCase>(
    () => UpdateCartItemUseCase(sl<CartRepository>()),
  );
  sl.registerLazySingleton<RemoveCartItemUseCase>(
    () => RemoveCartItemUseCase(sl<CartRepository>()),
  );
  sl.registerLazySingleton<ClearCartUseCase>(
    () => ClearCartUseCase(sl<CartRepository>()),
  );

  // Wishlist
  sl.registerLazySingleton<WishlistLocalDataSource>(
    () => WishlistLocalDataSource(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<WishlistRemoteDataSource>(
    () => WishlistRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(sl<WishlistRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetWishlistUseCase>(
    () => GetWishlistUseCase(sl<WishlistRepository>()),
  );
  sl.registerLazySingleton<AddWishlistItemUseCase>(
    () => AddWishlistItemUseCase(sl<WishlistRepository>()),
  );
  sl.registerLazySingleton<RemoveWishlistItemUseCase>(
    () => RemoveWishlistItemUseCase(sl<WishlistRepository>()),
  );

  // Order
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(sl<OrderRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetOrdersUseCase>(
    () => GetOrdersUseCase(sl<OrderRepository>()),
  );
  sl.registerLazySingleton<GetOrderByIdUseCase>(
    () => GetOrderByIdUseCase(sl<OrderRepository>()),
  );
  sl.registerLazySingleton<GetOrderTrackingUseCase>(
    () => GetOrderTrackingUseCase(sl<OrderRepository>()),
  );
  sl.registerLazySingleton<CancelOrderUseCase>(
    () => CancelOrderUseCase(sl<OrderRepository>()),
  );
  sl.registerLazySingleton<CreateOrderUseCase>(
    () => CreateOrderUseCase(sl<OrderRepository>()),
  );
  sl.registerLazySingleton<CreateGuestOrderUseCase>(
    () => CreateGuestOrderUseCase(sl<OrderRepository>()),
  );

  // Address
  sl.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(sl<AddressRemoteDataSource>()),
  );
  sl.registerLazySingleton<ListAddressesUseCase>(
    () => ListAddressesUseCase(sl<AddressRepository>()),
  );
  sl.registerLazySingleton<GetAddressByIdUseCase>(
    () => GetAddressByIdUseCase(sl<AddressRepository>()),
  );
  sl.registerLazySingleton<CreateAddressUseCase>(
    () => CreateAddressUseCase(sl<AddressRepository>()),
  );
  sl.registerLazySingleton<UpdateAddressUseCase>(
    () => UpdateAddressUseCase(sl<AddressRepository>()),
  );
  sl.registerLazySingleton<DeleteAddressUseCase>(
    () => DeleteAddressUseCase(sl<AddressRepository>()),
  );
  sl.registerLazySingleton<SetDefaultAddressUseCase>(
    () => SetDefaultAddressUseCase(sl<AddressRepository>()),
  );

  // Video (Inspiration)
  sl.registerLazySingleton<VideoRemoteDataSource>(
    () => VideoRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(sl<VideoRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetInspirationVideosUseCase>(
    () => GetInspirationVideosUseCase(sl<VideoRepository>()),
  );

  // Promotion (Coupons)
  sl.registerLazySingleton<PromotionRemoteDataSource>(
    () => PromotionRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<PromotionRepository>(
    () => PromotionRepositoryImpl(sl<PromotionRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetPromotionsUseCase>(
    () => GetPromotionsUseCase(sl<PromotionRepository>()),
  );
  sl.registerLazySingleton<ValidatePromotionUseCase>(
    () => ValidatePromotionUseCase(sl<PromotionRepository>()),
  );

  // Return
  sl.registerLazySingleton<ReturnRemoteDataSource>(
    () => ReturnRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<ReturnRepository>(
    () => ReturnRepositoryImpl(sl<ReturnRemoteDataSource>()),
  );
  sl.registerLazySingleton<ListReturnsUseCase>(
    () => ListReturnsUseCase(sl<ReturnRepository>()),
  );
  sl.registerLazySingleton<CreateReturnUseCase>(
    () => CreateReturnUseCase(sl<ReturnRepository>()),
  );

  // Shipping
  sl.registerLazySingleton<ShippingRemoteDataSource>(
    () => ShippingRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<ShippingRepository>(
    () => ShippingRepositoryImpl(sl<ShippingRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetShippingMethodsUseCase>(
    () => GetShippingMethodsUseCase(sl<ShippingRepository>()),
  );
  sl.registerLazySingleton<CalculateShippingUseCase>(
    () => CalculateShippingUseCase(sl<ShippingRepository>()),
  );

  // Tax
  sl.registerLazySingleton<TaxRemoteDataSource>(
    () => TaxRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<TaxRepository>(
    () => TaxRepositoryImpl(sl<TaxRemoteDataSource>()),
  );
  sl.registerLazySingleton<CalculateTaxUseCase>(
    () => CalculateTaxUseCase(sl<TaxRepository>()),
  );

  // Payment (Stripe)
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl<PaymentRemoteDataSource>()),
  );
  sl.registerLazySingleton<CreatePaymentIntentUseCase>(
    () => CreatePaymentIntentUseCase(sl<PaymentRepository>()),
  );

  // Rewards
  sl.registerLazySingleton<RewardsRemoteDataSource>(
    () => RewardsRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<RewardsRepository>(
    () => RewardsRepositoryImpl(sl<RewardsRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetRewardsSummaryUseCase>(
    () => GetRewardsSummaryUseCase(sl<RewardsRepository>()),
  );
  sl.registerLazySingleton<GetRewardsTransactionsUseCase>(
    () => GetRewardsTransactionsUseCase(sl<RewardsRepository>()),
  );
  sl.registerLazySingleton<RedeemRewardsUseCase>(
    () => RedeemRewardsUseCase(sl<RewardsRepository>()),
  );

  // Reviews
  sl.registerLazySingleton<ReviewRemoteDataSource>(
    () => ReviewRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(sl<ReviewRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetMyReviewsUseCase>(
    () => GetMyReviewsUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<GetProductReviewsUseCase>(
    () => GetProductReviewsUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<SubmitReviewUseCase>(
    () => SubmitReviewUseCase(sl<ReviewRepository>()),
  );

  // Product local cache (offline / SharedPreferences)
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSource(sl<SharedPreferences>()),
  );

  // Product recommendations (co-purchase API)
  sl.registerLazySingleton<GetRecommendationsUseCase>(
    () => GetRecommendationsUseCase(sl<ProductRepository>()),
  );

  // FCM push notifications
  sl.registerLazySingleton<FCMService>(
    () => FCMService(sl<DioClient>()),
  );

  // Checkout
  sl.registerFactory<CheckoutBloc>(
    () => CheckoutBloc(
      listAddressesUseCase: sl<ListAddressesUseCase>(),
      calculateShippingUseCase: sl<CalculateShippingUseCase>(),
      validatePromotionUseCase: sl<ValidatePromotionUseCase>(),
      createOrderUseCase: sl<CreateOrderUseCase>(),
    ),
  );
}

DioClient get dioClient => sl<DioClient>();
