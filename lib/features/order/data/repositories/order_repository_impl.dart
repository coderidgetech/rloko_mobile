import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../dto/order_dto.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._dataSource);

  final OrderRemoteDataSource _dataSource;

  /// Serializes an order item, including per-item gift fields when set so the
  /// backend records which units are gifts (matches web's conditional spread).
  static Map<String, dynamic> _itemToJson(OrderItemEntity e) => {
        'product_id': e.productId,
        'product_name': e.productName,
        'image': e.image,
        'price': e.price,
        'size': e.size,
        'quantity': e.quantity,
        if (e.isGift == true) 'is_gift': true,
        if (e.isGift == true && e.giftWrapColor != null)
          'gift_wrap_color': e.giftWrapColor,
        if (e.isGift == true && e.giftMessage != null)
          'gift_message': e.giftMessage,
      };

  @override
  Future<OrderListResult> list({int? limit, int? skip, String? status}) async {
    try {
      final dto = await _dataSource.list(limit: limit, skip: skip, status: status);
      return OrderListResult(
        orders: dto.orders.map((e) => e.toEntity()).toList(),
        total: dto.total,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<OrderEntity> getById(String id) async {
    try {
      final dto = await _dataSource.getById(id);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<OrderEntity> getByOrderNumber(String orderNumber) async {
    try {
      final dto = await _dataSource.getByOrderNumber(orderNumber);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<List<OrderTrackingUpdateEntity>> getTracking(String orderId) async {
    try {
      final list = await _dataSource.getTracking(orderId);
      return list
          .map((e) => OrderTrackingUpdateEntity(
                status: e.status,
                description: e.description,
                location: e.location,
                createdAt: e.createdAt,
              ))
          .toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> cancel(String orderId, {String? reason}) async {
    try {
      await _dataSource.cancel(orderId, reason: reason);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<OrderEntity> create({
    required List<OrderItemEntity> items,
    required ShippingInfoEntity shippingInfo,
    required String paymentMethod,
    Map<String, dynamic>? paymentInfo,
    String? promotionCode,
    double giftPackingCharge = 0,
    String? idempotencyKey,
    String? shippingCarrier,
    String? shippingService,
  }) async {
    try {
      final itemsJson = items.map(_itemToJson).toList();
      final shippingJson = {
        'first_name': shippingInfo.firstName,
        'last_name': shippingInfo.lastName,
        'email': shippingInfo.email,
        'phone': shippingInfo.phone,
        'address': shippingInfo.address,
        'city': shippingInfo.city,
        'state': shippingInfo.state,
        'zip_code': shippingInfo.zipCode,
        'country': shippingInfo.country,
      };
      final request = CreateOrderRequestDto(
        items: itemsJson,
        shippingInfo: shippingJson,
        paymentMethod: paymentMethod,
        paymentInfo: paymentInfo,
        promotionCode: promotionCode,
        shippingCarrier: shippingCarrier,
        shippingService: shippingService,
        giftPackingCharge: giftPackingCharge > 0 ? giftPackingCharge : null,
      );
      final dto = await _dataSource.create(request, idempotencyKey: idempotencyKey);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<OrderEntity> createGuest({
    required String guestEmail,
    required String guestName,
    required List<OrderItemEntity> items,
    required ShippingInfoEntity shippingInfo,
    String? promotionCode,
    String? shippingCarrier,
    String? shippingService,
  }) async {
    try {
      final itemsJson = items.map(_itemToJson).toList();
      final shippingJson = {
        'first_name': shippingInfo.firstName,
        'last_name': shippingInfo.lastName,
        'email': shippingInfo.email,
        'phone': shippingInfo.phone,
        'address': shippingInfo.address,
        'city': shippingInfo.city,
        'state': shippingInfo.state,
        'zip_code': shippingInfo.zipCode,
        'country': shippingInfo.country,
      };
      final request = CreateGuestOrderRequestDto(
        guestEmail: guestEmail,
        guestName: guestName,
        items: itemsJson,
        shippingInfo: shippingJson,
        promotionCode: promotionCode,
        shippingCarrier: shippingCarrier,
        shippingService: shippingService,
      );
      final dto = await _dataSource.createGuest(request);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
