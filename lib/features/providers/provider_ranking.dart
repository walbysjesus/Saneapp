double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

int _extractResponseMinutes(Map<String, dynamic> service) {
  final rawMinutes = service['responseTimeMinutes'];
  if (rawMinutes is num) {
    return rawMinutes.toInt();
  }

  final responseTime = service['responseTime']?.toString().trim() ?? '';
  final match = RegExp(r'(\d+)').firstMatch(responseTime);
  if (match != null) {
    return int.tryParse(match.group(1) ?? '') ?? 99999;
  }

  return 99999;
}

DateTime _extractDate(Map<String, dynamic> service) {
  final updatedAt = service['updatedAt'];
  if (updatedAt is DateTime) {
    return updatedAt;
  }

  final createdAt = service['createdAt'];
  if (createdAt is DateTime) {
    return createdAt;
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

int _tierWeight(Map<String, dynamic> service) {
  final tier = (service['commercialTier']?.toString() ?? '')
      .trim()
      .toUpperCase();
  switch (tier) {
    case 'A':
      return 4;
    case 'B':
      return 3;
    case 'C':
      return 2;
    case 'D':
      return 1;
    default:
      return 0;
  }
}

double computeCommercialRelevanceScore(Map<String, dynamic> service) {
  final rating = _asDouble(service['rating'], fallback: 0).clamp(0, 5);
  final ratingCount = _asDouble(service['ratingCount'], fallback: 0);
  final tierWeight = _tierWeight(service).toDouble();
  final emergencyBonus =
      service['emergencyAvailability'] == true ||
          service['isEmergencyAvailable'] == true
      ? 8
      : 0;
  final licenseBonus = service['requiresLicense'] == true ? 4 : 0;

  final responseMinutes = _extractResponseMinutes(service);
  final responseScore = responseMinutes <= 0
      ? 0
      : (60 / responseMinutes.clamp(1, 1440));

  // Peso compuesto: reputacion + volumen + tiempo de respuesta + calidad comercial
  return (rating * 20) +
      ratingCount.clamp(0, 200) * 0.2 +
      (responseScore * 8) +
      (tierWeight * 5) +
      emergencyBonus +
      licenseBonus;
}

enum ProviderSortOption {
  relevance,
  newest,
  topRated,
  fastestResponse,
  priceLow,
}

List<Map<String, dynamic>> sortProviderServices(
  List<Map<String, dynamic>> services,
  ProviderSortOption option,
) {
  final sorted = List<Map<String, dynamic>>.from(services);

  switch (option) {
    case ProviderSortOption.newest:
      sorted.sort((a, b) => _extractDate(b).compareTo(_extractDate(a)));
      break;
    case ProviderSortOption.topRated:
      sorted.sort((a, b) {
        final bRating = _asDouble(b['rating']);
        final aRating = _asDouble(a['rating']);
        final byRating = bRating.compareTo(aRating);
        if (byRating != 0) {
          return byRating;
        }
        final bCount = _asDouble(b['ratingCount']);
        final aCount = _asDouble(a['ratingCount']);
        return bCount.compareTo(aCount);
      });
      break;
    case ProviderSortOption.fastestResponse:
      sorted.sort(
        (a, b) =>
            _extractResponseMinutes(a).compareTo(_extractResponseMinutes(b)),
      );
      break;
    case ProviderSortOption.priceLow:
      sorted.sort((a, b) {
        final aPrice = _asDouble(
          a['priceFrom'],
          fallback: _asDouble(a['price']),
        );
        final bPrice = _asDouble(
          b['priceFrom'],
          fallback: _asDouble(b['price']),
        );
        return aPrice.compareTo(bPrice);
      });
      break;
    case ProviderSortOption.relevance:
      sorted.sort((a, b) {
        final bScore = computeCommercialRelevanceScore(b);
        final aScore = computeCommercialRelevanceScore(a);
        return bScore.compareTo(aScore);
      });
      break;
  }

  return sorted;
}
