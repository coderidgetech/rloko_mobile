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
  final String createdAt;

  factory RewardsTransaction.fromJson(Map<String, dynamic> json) {
    return RewardsTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'earned',
      points: (json['points'] as num?)?.toInt() ?? 0,
      reference: json['reference']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, type, points, reference, description, createdAt];
}
