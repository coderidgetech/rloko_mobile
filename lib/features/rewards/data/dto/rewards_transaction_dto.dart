import '../../domain/entities/rewards_transaction.dart';

class RewardsTransactionDto {
  const RewardsTransactionDto({
    required this.id,
    required this.type,
    required this.points,
    required this.reference,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int points;
  final String reference;
  final String description;
  final DateTime createdAt;

  factory RewardsTransactionDto.fromJson(Map<String, dynamic> json) {
    return RewardsTransactionDto(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'earned',
      points: (json['points'] as num?)?.toInt() ?? 0,
      reference: json['reference']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime(0)
          : DateTime(0),
    );
  }

  RewardsTransaction toEntity() => RewardsTransaction(
        id: id,
        type: type,
        points: points,
        reference: reference,
        description: description,
        createdAt: createdAt,
      );
}
