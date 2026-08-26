String formatDistance(double distance) {
  if (distance <= 0.0) {
    return "0 m";
  }
  if (distance < 1.0) {
    return "${(distance * 1000).toInt()} m";
  } else {
    if (distance == distance.toInt().toDouble()) {
      return "${distance.toInt()} km";
    } else {
      final String twoDecimals = distance.toStringAsFixed(2);
      if (twoDecimals.endsWith('0')) {
        return "${distance.toStringAsFixed(1)} km";
      } else {
        return "$twoDecimals km";
      }
    }
  }
}
