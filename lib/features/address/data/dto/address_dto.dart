import '../../domain/entities/address_entity.dart';

String _str(dynamic v) => v?.toString() ?? '';
String _date(dynamic v) =>
    v != null ? (DateTime.tryParse(v.toString())?.toIso8601String() ?? '') : '';

class AddressDto {
  AddressDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.addressLine,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.mobile,
    required this.country,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Handles id as string or MongoDB extended JSON object (e.g. {"$oid": "..."}).
  static String _idFromJson(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map && v['\$oid'] != null) return v['\$oid'].toString();
    return v.toString();
  }

  factory AddressDto.fromJson(Map<String, dynamic> json) {
    return AddressDto(
      id: _idFromJson(json['id']),
      userId: _str(json['user_id']),
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'OTHER',
      addressLine: json['address_line'] as String? ?? '',
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      country: json['country'] as String? ?? 'US',
      isDefault: json['is_default'] == true,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String type;
  final String addressLine;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String mobile;
  final String country;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  AddressEntity toEntity() => AddressEntity(
        id: id,
        userId: userId,
        name: name,
        type: type,
        addressLine: addressLine,
        addressLine2: addressLine2,
        city: city,
        state: state,
        pincode: pincode,
        mobile: mobile,
        country: country,
        isDefault: isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'address_line': addressLine,
        if (addressLine2 != null && addressLine2!.isNotEmpty) 'address_line2': addressLine2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'mobile': mobile,
        'country': country,
      };
}
