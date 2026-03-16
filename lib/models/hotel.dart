class Hotel {
  final int hotelId;
  final String name;
  final double lat;
  final double lng;
  final double? starRating;
  final double? reviewScore;
  final int? reviewCount;
  final double? dailyRate;
  final double? crossedOutRate;
  final String? currency;
  final String? imageUrl;
  final String? bookingUrl;
  final bool includeBreakfast;
  final bool freeWifi;

  const Hotel({
    required this.hotelId,
    required this.name,
    required this.lat,
    required this.lng,
    this.starRating,
    this.reviewScore,
    this.reviewCount,
    this.dailyRate,
    this.crossedOutRate,
    this.currency,
    this.imageUrl,
    this.bookingUrl,
    this.includeBreakfast = false,
    this.freeWifi = false,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      hotelId: json['hotelId'] as int? ?? json['id'] as int? ?? 0,
      // API uses 'hotelName', web model uses 'name'
      name: json['hotelName'] as String? ?? json['name'] as String? ?? '',
      lat: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 0,
      starRating: (json['starRating'] as num?)?.toDouble(),
      reviewScore: (json['reviewScore'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      // API uses 'dailyRate', not 'pricePerNight'
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? (json['pricePerNight'] as num?)?.toDouble(),
      crossedOutRate: (json['crossedOutRate'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      // API uses 'imageURL', not 'imageUrl'
      imageUrl: json['imageURL'] as String? ?? json['imageUrl'] as String?,
      // API uses 'landingURL', not 'bookingUrl'
      bookingUrl: json['landingURL'] as String? ?? json['bookingUrl'] as String?,
      includeBreakfast: json['includeBreakfast'] as bool? ?? false,
      freeWifi: json['freeWifi'] as bool? ?? false,
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String get formattedPrice {
    if (dailyRate == null) return '';
    final symbol = currency == 'KRW' ? '₩'
        : currency == 'JPY' ? '¥'
        : '\$';
    return '$symbol${_formatNumber(dailyRate!.round())}';
  }

  String? get formattedCrossedOutPrice {
    if (crossedOutRate == null || dailyRate == null) return null;
    if (crossedOutRate! <= dailyRate!) return null;
    final symbol = currency == 'KRW' ? '₩'
        : currency == 'JPY' ? '¥'
        : '\$';
    return '$symbol${_formatNumber(crossedOutRate!.round())}';
  }

  String get formattedRating {
    if (reviewScore == null) return '';
    return reviewScore!.toStringAsFixed(1);
  }

  int get discountPercent {
    if (crossedOutRate == null || dailyRate == null || crossedOutRate! <= dailyRate!) return 0;
    return ((1 - dailyRate! / crossedOutRate!) * 100).round();
  }
}
