import '../../domain/entities/user_entity.dart';

class UserDto {
  UserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.vendorId,
    this.avatar,
    this.phone,
    this.birthday,
    this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: _string(json['id']),
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      vendorId: json['vendor_id'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'].toString())?.toIso8601String()
          : null,
      active: json['active'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toIso8601String() ?? ''
          : '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toIso8601String() ?? ''
          : '',
    );
  }

  final String id;
  final String email;
  final String name;
  final String role;
  final String? vendorId;
  final String? avatar;
  final String? phone;
  final String? birthday;
  final bool? active;
  final String createdAt;
  final String updatedAt;

  static String _string(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        name: name,
        role: role,
        vendorId: vendorId,
        avatar: avatar,
        phone: phone,
        birthday: birthday,
        active: active,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
