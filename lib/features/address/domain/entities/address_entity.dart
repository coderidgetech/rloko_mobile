import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  const AddressEntity({
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

  final String id;
  final String userId;
  final String name;
  final String type; // HOME, OFFICE, OTHER
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

  @override
  List<Object?> get props => [id];
}
