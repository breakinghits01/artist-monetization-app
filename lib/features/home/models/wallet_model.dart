/// User wallet model
class WalletModel {
  final int tokens;
  final double balance;
  final String currency;

  const WalletModel({
    required this.tokens,
    required this.balance,
    this.currency = 'USD',
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      tokens: (json['tokens'] ?? json['coins']) as int? ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokens': tokens,
      'balance': balance,
      'currency': currency,
    };
  }

  /// Format tokens with thousands separator
  String get formattedTokens {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    } else if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}K';
    }
    return tokens.toString();
  }

  /// Format balance as currency
  String get formattedBalance {
    return '\$${balance.toStringAsFixed(2)}';
  }

  WalletModel copyWith({
    int? tokens,
    double? balance,
    String? currency,
  }) {
    return WalletModel(
      tokens: tokens ?? this.tokens,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
    );
  }
}
