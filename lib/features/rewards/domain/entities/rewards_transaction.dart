import 'package:equatable/equatable.dart';

class RewardsTransaction extends Equatable {
  const RewardsTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.reference,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String type; // "earned" | "redeemed"
  final int points;
  final String reference;
  final String description;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, type, points, reference, description, createdAt];
}
