import 'constants.dart';

/// 入力値のバリデーションを行うユーティリティクラス
class Validators {
  /// メールアドレスのバリデーション
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.emailRequired;
    }

    // メールアドレスの正規表現パターン
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return ErrorMessages.emailInvalid;
    }

    if (value.length > ValidationConstants.emailMaxLength) {
      return '${ValidationConstants.emailMaxLength}文字以内で入力してください';
    }

    return null;
  }

  /// パスワードのバリデーション
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.passwordRequired;
    }

    if (value.length < ValidationConstants.passwordMinLength) {
      return ErrorMessages.passwordTooShort;
    }

    if (value.length > ValidationConstants.passwordMaxLength) {
      return '${ValidationConstants.passwordMaxLength}文字以内で入力してください';
    }

    return null;
  }

  /// パスワード確認のバリデーション
  static String? validatePasswordConfirmation(
    String? value,
    String? password,
  ) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.passwordRequired;
    }

    if (value != password) {
      return ErrorMessages.passwordMismatch;
    }

    return null;
  }

  /// 店舗名のバリデーション
  static String? validateStoreName(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.storeNameRequired;
    }

    if (value.length > ValidationConstants.storeNameMaxLength) {
      return '${ValidationConstants.storeNameMaxLength}文字以内で入力してください';
    }

    return null;
  }

  /// 住所のバリデーション
  static String? validateAddress(String? value, {bool required = true}) {
    if (required && (value == null || value.isEmpty)) {
      return ErrorMessages.addressRequired;
    }

    if (value != null && value.length > ValidationConstants.addressMaxLength) {
      return '${ValidationConstants.addressMaxLength}文字以内で入力してください';
    }

    return null;
  }

  /// 電話番号のバリデーション
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.phoneNumberRequired;
    }

    // 数字とハイフンのみを許可
    final phoneRegex = RegExp(r'^[0-9-]+$');
    if (!phoneRegex.hasMatch(value)) {
      return ErrorMessages.phoneNumberInvalid;
    }

    // ハイフンを除去
    final digitsOnly = value.replaceAll('-', '');

    // 10桁または11桁であることを確認
    if (digitsOnly.length < 10 || digitsOnly.length > 11) {
      return ErrorMessages.phoneNumberInvalid;
    }

    if (value.length > ValidationConstants.phoneNumberMaxLength) {
      return '${ValidationConstants.phoneNumberMaxLength}文字以内で入力してください';
    }

    return null;
  }

  /// インボイス番号のバリデーション（T + 13桁の数字）
  static String? validateInvoiceNumber(String? value, {bool required = true}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (required && (value == null || value.isEmpty)) {
      return 'インボイス番号を入力してください';
    }

    // T + 13桁の数字のパターン
    final invoiceRegex = RegExp(r'^T\d{13}$');
    if (value != null && !invoiceRegex.hasMatch(value)) {
      return ErrorMessages.invoiceNumberInvalid;
    }

    return null;
  }

  /// 宛名のバリデーション
  static String? validateRecipientName(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.recipientNameRequired;
    }

    if (value.length > ValidationConstants.recipientNameMaxLength) {
      return '${ValidationConstants.recipientNameMaxLength}文字以内で入力してください';
    }

    return null;
  }

  /// 但し書きのバリデーション
  static String? validateMemo(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.memoRequired;
    }

    if (value.length > ValidationConstants.memoMaxLength) {
      return '${ValidationConstants.memoMaxLength}文字以内で入力してください';
    }

    return null;
  }

  /// 金額のバリデーション
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.amountRequired;
    }

    // カンマを除去
    final cleanValue = value.replaceAll(',', '');

    // 数字のみを許可
    final numberRegex = RegExp(r'^\d+$');
    if (!numberRegex.hasMatch(cleanValue)) {
      return ErrorMessages.amountInvalid;
    }

    final amount = int.tryParse(cleanValue);
    if (amount == null) {
      return ErrorMessages.amountInvalid;
    }

    if (amount <= 0) {
      return '1円以上の金額を入力してください';
    }

    if (amount > ValidationConstants.maxAmount) {
      return ErrorMessages.amountTooLarge;
    }

    return null;
  }

  /// 金額文字列を整数に変換
  static int? parseAmount(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final cleanValue = value.replaceAll(',', '');
    return int.tryParse(cleanValue);
  }

  /// 必須項目の汎用バリデーション
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldNameを入力してください';
    }
    return null;
  }
}

/// フォーマット用のユーティリティクラス
class Formatters {
  /// 金額をカンマ区切りでフォーマット
  static String formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// 電話番号をハイフン区切りでフォーマット（11桁の場合）
  static String formatPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length == 11) {
      // 090-1234-5678 形式
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    } else if (digitsOnly.length == 10) {
      // 03-1234-5678 形式
      return '${digitsOnly.substring(0, 2)}-${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6)}';
    }

    return phoneNumber;
  }

  /// 日付を「YYYY年MM月DD日」形式でフォーマット
  static String formatDate(DateTime date) {
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
  }

  /// 日付を「YYYY/MM/DD」形式でフォーマット
  static String formatDateSlash(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  /// 日時を「YYYY年MM月DD日 HH:mm」形式でフォーマット
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
