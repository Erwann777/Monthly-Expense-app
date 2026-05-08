class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

class AppCurrencies {
  static const List<CurrencyModel> currencies = [
    CurrencyModel(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    CurrencyModel(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    CurrencyModel(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    CurrencyModel(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    CurrencyModel(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾'),
    CurrencyModel(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
    CurrencyModel(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', flag: '🇮🇩'),
    CurrencyModel(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭'),
    CurrencyModel(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭'),
    CurrencyModel(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', flag: '🇻🇳'),
    CurrencyModel(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
    CurrencyModel(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    CurrencyModel(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    CurrencyModel(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
    CurrencyModel(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
    CurrencyModel(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),
    CurrencyModel(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$', flag: '🇳🇿'),
    CurrencyModel(code: 'TWD', name: 'Taiwan Dollar', symbol: 'NT\$', flag: '🇹🇼'),
    CurrencyModel(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰'),
    CurrencyModel(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    CurrencyModel(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
    CurrencyModel(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
    CurrencyModel(code: 'MXN', name: 'Mexican Peso', symbol: 'MX\$', flag: '🇲🇽'),
    CurrencyModel(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦'),
    CurrencyModel(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
    CurrencyModel(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪'),
    CurrencyModel(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', flag: '🇳🇴'),
    CurrencyModel(code: 'DKK', name: 'Danish Krone', symbol: 'kr', flag: '🇩🇰'),
    CurrencyModel(code: 'PLN', name: 'Polish Zloty', symbol: 'zł', flag: '🇵🇱'),
    CurrencyModel(code: 'RUB', name: 'Russian Ruble', symbol: '₽', flag: '🇷🇺'),
    CurrencyModel(code: 'ARS', name: 'Argentine Peso', symbol: '\$', flag: '🇦🇷'),
    CurrencyModel(code: 'CLP', name: 'Chilean Peso', symbol: '\$', flag: '🇨🇱'),
    CurrencyModel(code: 'COP', name: 'Colombian Peso', symbol: '\$', flag: '🇨🇴'),
    CurrencyModel(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', flag: '🇵🇪'),
    CurrencyModel(code: 'EGP', name: 'Egyptian Pound', symbol: '£', flag: '🇪🇬'),
    CurrencyModel(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬'),
    CurrencyModel(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', flag: '🇰🇪'),
    CurrencyModel(code: 'GHS', name: 'Ghanaian Cedi', symbol: '₵', flag: '🇬🇭'),
    CurrencyModel(code: 'MAD', name: 'Moroccan Dirham', symbol: 'د.م.', flag: '🇲🇦'),
    CurrencyModel(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', flag: '🇵🇰'),
    CurrencyModel(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳', flag: '🇧🇩'),
    CurrencyModel(code: 'LKR', name: 'Sri Lankan Rupee', symbol: '₨', flag: '🇱🇰'),
    CurrencyModel(code: 'MMK', name: 'Myanmar Kyat', symbol: 'K', flag: '🇲🇲'),
    CurrencyModel(code: 'KHR', name: 'Cambodian Riel', symbol: '៛', flag: '🇰🇭'),
    CurrencyModel(code: 'ILS', name: 'Israeli Shekel', symbol: '₪', flag: '🇮🇱'),
    CurrencyModel(code: 'QAR', name: 'Qatari Riyal', symbol: '﷼', flag: '🇶🇦'),
    CurrencyModel(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'د.ك', flag: '🇰🇼'),
    CurrencyModel(code: 'BHD', name: 'Bahraini Dinar', symbol: '.د.ب', flag: '🇧🇭'),
    CurrencyModel(code: 'OMR', name: 'Omani Rial', symbol: '﷼', flag: '🇴🇲'),
    CurrencyModel(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč', flag: '🇨🇿'),
    CurrencyModel(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft', flag: '🇭🇺'),
    CurrencyModel(code: 'RON', name: 'Romanian Leu', symbol: 'lei', flag: '🇷🇴'),
    CurrencyModel(code: 'BGN', name: 'Bulgarian Lev', symbol: 'лв', flag: '🇧🇬'),
    CurrencyModel(code: 'HRK', name: 'Croatian Kuna', symbol: 'kn', flag: '🇭🇷'),
    CurrencyModel(code: 'UAH', name: 'Ukrainian Hryvnia', symbol: '₴', flag: '🇺🇦'),
  ];

  static CurrencyModel getByCode(String code) {
    return currencies.firstWhere(
      (c) => c.code == code,
      orElse: () => currencies.first,
    );
  }
}
