import '../../domain/entities/order_entity.dart';

String _str(dynamic v) => v?.toString() ?? '';
double _double(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
double? _doubleOrNull(dynamic v) => v == null ? null : ((v is num) ? v.toDouble() : double.tryParse(v.toString()));
String _date(dynamic v) => v != null ? (DateTime.tryParse(v.toString())?.toIso8601String() ?? '') : '';

class OrderItemDto {
  OrderItemDto({
    required this.productId,
    required this.productName,
    required this.image,
    required this.price,
    required this.size,
    required this.quantity,
    this.isGift,
    this.giftWrapColor,
    this.giftMessage,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: _str(json['product_id']),
      productName: json['product_name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      price: _double(json['price']),
      size: json['size'] as String? ?? '',
      quantity: json['quantity'] is int ? json['quantity'] as int : 0,
      isGift: json['is_gift'] as bool?,
      giftWrapColor: json['gift_wrap_color'] as String?,
      giftMessage: json['gift_message'] as String?,
    );
  }

  final String productId;
  final String productName;
  final String image;
  final double price;
  final String size;
  final int quantity;
  final bool? isGift;
  final String? giftWrapColor;
  final String? giftMessage;

  OrderItemEntity toEntity() => OrderItemEntity(
        productId: productId,
        productName: productName,
        image: image,
        price: price,
        size: size,
        quantity: quantity,
        isGift: isGift,
        giftWrapColor: giftWrapColor,
        giftMessage: giftMessage,
      );
}

class ShippingInfoDto {
  ShippingInfoDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory ShippingInfoDto.fromJson(Map<String, dynamic> json) {
    return ShippingInfoDto(
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  ShippingInfoEntity toEntity() => ShippingInfoEntity(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
      );

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'country': country,
      };
}

/// Request body for POST /orders/guest (unauthenticated)
class CreateGuestOrderRequestDto {
  CreateGuestOrderRequestDto({
    required this.guestEmail,
    required this.guestName,
    required this.items,
    required this.shippingInfo,
    this.promotionCode,
    this.shippingCarrier,
    this.shippingService,
  });

  final String guestEmail;
  final String guestName;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> shippingInfo;
  final String? promotionCode;
  // Customer-selected shipping rate so fulfillment buys that rate, not the cheapest.
  final String? shippingCarrier;
  final String? shippingService;

  Map<String, dynamic> toJson() => {
        'guest_email': guestEmail,
        'guest_name': guestName,
        'items': items,
        'shipping_info': shippingInfo,
        if (promotionCode != null && promotionCode!.isNotEmpty) 'promotion_code': promotionCode,
        if (shippingCarrier != null && shippingCarrier!.isNotEmpty) 'shipping_carrier': shippingCarrier,
        if (shippingService != null && shippingService!.isNotEmpty) 'shipping_service': shippingService,
      };
}

/// Request body for POST /orders
class CreateOrderRequestDto {
  CreateOrderRequestDto({
    required this.items,
    required this.shippingInfo,
    required this.paymentMethod,
    this.paymentInfo,
    this.promotionCode,
    this.giftPackingCharge,
    this.shippingCarrier,
    this.shippingService,
  });

  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> shippingInfo;
  final String paymentMethod;
  final Map<String, dynamic>? paymentInfo;
  final String? promotionCode;
  final double? giftPackingCharge;
  // Customer-selected shipping rate so fulfillment buys that rate, not the cheapest.
  final String? shippingCarrier;
  final String? shippingService;

  Map<String, dynamic> toJson() => {
        'items': items,
        'shipping_info': shippingInfo,
        'payment_method': paymentMethod,
        if (paymentInfo != null && paymentInfo!.isNotEmpty) 'payment_info': paymentInfo,
        if (promotionCode != null && promotionCode!.isNotEmpty) 'promotion_code': promotionCode,
        if (giftPackingCharge != null && giftPackingCharge! > 0) 'gift_packing_charge': giftPackingCharge,
        if (shippingCarrier != null && shippingCarrier!.isNotEmpty) 'shipping_carrier': shippingCarrier,
        if (shippingService != null && shippingService!.isNotEmpty) 'shipping_service': shippingService,
      };
}

class OrderDto {
  OrderDto({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.shippingInfo,
    required this.subtotal,
    required this.discount,
    required this.shippingCost,
    this.giftPackingCharge,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? (itemsRaw).map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>)).toList()
        : <OrderItemDto>[];
    final shipRaw = json['shipping_info'];
    final shippingInfo = shipRaw is Map<String, dynamic>
        ? ShippingInfoDto.fromJson(shipRaw)
        : ShippingInfoDto(firstName: '', lastName: '', email: '', phone: '', address: '', city: '', state: '', zipCode: '', country: '');
    return OrderDto(
      id: _str(json['id']),
      orderNumber: json['order_number'] as String? ?? '',
      userId: _str(json['user_id']),
      items: items,
      shippingInfo: shippingInfo,
      subtotal: _double(json['subtotal']),
      discount: _double(json['discount']),
      shippingCost: _double(json['shipping_cost']),
      giftPackingCharge: _doubleOrNull(json['gift_packing_charge']),
      tax: _double(json['tax']),
      total: _double(json['total']),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      trackingNumber: json['tracking_number'] as String?,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  final String id;
  final String orderNumber;
  final String userId;
  final List<OrderItemDto> items;
  final ShippingInfoDto shippingInfo;
  final double subtotal;
  final double discount;
  final double shippingCost;
  final double? giftPackingCharge;
  final double tax;
  final double total;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String? trackingNumber;
  final String createdAt;
  final String updatedAt;

  OrderEntity toEntity() => OrderEntity(
        id: id,
        orderNumber: orderNumber,
        userId: userId,
        items: items.map((e) => e.toEntity()).toList(),
        shippingInfo: shippingInfo.toEntity(),
        subtotal: subtotal,
        discount: discount,
        shippingCost: shippingCost,
        giftPackingCharge: giftPackingCharge,
        tax: tax,
        total: total,
        status: status,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        trackingNumber: trackingNumber,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class OrderListResponseDto {
  OrderListResponseDto({required this.orders, required this.total});

  factory OrderListResponseDto.fromJson(Map<String, dynamic> json) {
    final ordersRaw = json['orders'];
    final orders = ordersRaw is List
        ? (ordersRaw).map((e) => OrderDto.fromJson(e as Map<String, dynamic>)).toList()
        : <OrderDto>[];
    return OrderListResponseDto(
      orders: orders,
      total: json['total'] is int ? json['total'] as int : 0,
    );
  }

  final List<OrderDto> orders;
  final int total;
}

class OrderTrackingUpdateDto {
  OrderTrackingUpdateDto({
    required this.status,
    this.description,
    this.location,
    required this.createdAt,
  });

  factory OrderTrackingUpdateDto.fromJson(Map<String, dynamic> json) {
    return OrderTrackingUpdateDto(
      status: json['status'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      createdAt: _date(json['created_at']),
    );
  }

  final String status;
  final String? description;
  final String? location;
  final String createdAt;
}
