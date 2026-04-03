class VietQr {
  static String buildImageUrl({
    required String bankId,
    required String accountNo,
    required int amount,
    String template = 'compact2',
    String? addInfo,
    String? accountName,
  }) {
    final safeBankId = Uri.encodeComponent(bankId.trim());
    final safeAccountNo = Uri.encodeComponent(accountNo.trim());
    final safeTemplate = Uri.encodeComponent(template.trim());

    final query = <String, String>{
      if (amount > 0) 'amount': amount.toString(),
      if (addInfo != null && addInfo.trim().isNotEmpty)
        'addInfo': addInfo.trim(),
      if (accountName != null && accountName.trim().isNotEmpty)
        'accountName': accountName.trim(),
    };

    return Uri(
      scheme: 'https',
      host: 'img.vietqr.io',
      path: '/image/$safeBankId-$safeAccountNo-$safeTemplate.png',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

