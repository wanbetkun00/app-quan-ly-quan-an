// Helper extension for Vietnamese Dong currency formatting
extension VndFormat on double {
  String toVnd() {
    return '${toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }
}

