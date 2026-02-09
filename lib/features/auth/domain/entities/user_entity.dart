import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
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

  final String id;
  final String email;
  final String name;
  final String role; // customer, admin, vendor
  final String? vendorId;
  final String? avatar;
  final String? phone;
  final String? birthday;
  final bool? active;
  final String createdAt;
  final String updatedAt;

  @override
  List<Object?> get props => [id, email, name, role];
}
