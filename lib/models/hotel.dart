class Hotel {
  final int hotelId;
  final String name;
  final double lat;
  final double lng;
  final double? starRating;
  final double? reviewScore;
  final int? reviewCount;
  final double? pricePerNight;
  final String? currency;
  final String? imageUrl;
  final String? bookingUrl;
  final String? address;

  const Hotel({
    required this.hotelId,
    required this.name,
    required this.lat,
    required this.lng,
    this.starRating,
    this.reviewScore,
    this.reviewCount,
    this.pricePerNight,
    this.currency,
    this.imageUrl,
    this.bookingUrl,
    this.address,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      hotelId: json['hotelId'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['hotelName'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? json['lon'] as double? ?? 0,
      starRating: (json['starRating'] as num?)?.toDouble(),
      reviewScore: (json['reviewScore'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int? ?? json['reviews'] as int?,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      bookingUrl: json['bookingUrl'] as String? ?? json['url'] as String?,
      address: json['address'] as String?,
    );
  }

  String get formattedPrice {
    if (pricePerNight == null) return '';
    final symbol = currency == 'KRW'
        ? '₩'
        : currency == 'JPY'
            ? '¥'
            : '\$';
    return '$symbol${pricePerNight!.round()}';
  }

  String get formattedRating {
    if (reviewScore == null) return '';
    return reviewScore!.toStringAsFixed(1);
  }
}
