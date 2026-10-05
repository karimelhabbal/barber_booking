import '../../domain/failures/payment_failure.dart';

/// INTEGRATION POINT: move these to your app's localization (l10n) if you have one.
class PaymentStrings {
  const PaymentStrings._();

  static const payTitle = 'الدفع';
  static const total = 'الإجمالي';
  static const chooseMethod = 'اختر طريقة الدفع';
  static const online = 'دفع إلكتروني';
  static const onlineSub = 'بطاقة بنكية أو محفظة إلكترونية';
  static const cash = 'الدفع كاش في الصالون';
  static const cashSub = 'ادفع عند الوصول للصالون';
  static const payNow = 'ادفع الآن';
  static const confirmCash = 'تأكيد الدفع كاش';
  static const verifying = 'جاري التحقق من عملية الدفع…';
  static const verifyingSlow = 'التحقق يأخذ وقتاً أطول من المعتاد. لو تم الخصم سيظهر التأكيد تلقائياً.';
  static const refresh = 'تحديث الحالة';
  static const paidOk = 'تم الدفع بنجاح';
  static const cashOk = 'تم تسجيل الدفع كاش. ادفع في الصالون عند الحضور.';
  static const failed = 'لم تكتمل عملية الدفع';
  static const tryAgain = 'حاول مرة أخرى';
  static const done = 'تم';
  static const noMethods = 'لا توجد طرق دفع متاحة لهذا الصالون';

  static const subscriptionTitle = 'الاشتراك';
  static const choosePlan = 'اختر الباقة';
  static const subscribe = 'اشترك';
  static const renew = 'تجديد';
  static const monthly = 'شهري';
  static const yearly = 'سنوي';
  static const activeUntil = 'الاشتراك فعّال حتى';
  static const expired = 'انتهى الاشتراك';
  static const noSubscription = 'لا يوجد اشتراك فعّال';
  static const subscriptionActivated = 'تم تفعيل الاشتراك';

  static const payoutTitle = 'بيانات استلام الأرباح';
  static const wallet = 'محفظة إلكترونية';
  static const iban = 'حساب بنكي (IBAN)';
  static const holderName = 'اسم صاحب الحساب';
  static const walletNumber = 'رقم المحفظة';
  static const ibanNumber = 'رقم الـ IBAN';
  static const save = 'حفظ';
  static const saved = 'تم الحفظ';

  static String errorFor(PaymentFailure f) {
    switch (f.reason) {
      case 'online_payment_disabled_for_shop':
        return 'الدفع الإلكتروني غير متاح لهذا الصالون';
      case 'cash_payment_disabled_for_shop':
        return 'الدفع كاش غير متاح لهذا الصالون';
      case 'booking_already_has_an_active_payment':
        return 'هذا الحجز عليه عملية دفع قائمة بالفعل';
      case 'booking_not_payable':
        return 'لا يمكن الدفع لهذا الحجز حالياً';
      case 'payment_provider_unavailable':
        return 'خدمة الدفع غير متاحة مؤقتاً، حاول بعد قليل';
      case 'wallet_number_must_be_egyptian_mobile':
        return 'رقم المحفظة يجب أن يكون رقم موبايل مصري صحيح';
      case 'iban_invalid':
        return 'رقم الـ IBAN غير صحيح';
      case 'account_holder_name_invalid':
        return 'اسم صاحب الحساب غير صحيح';
      case 'only_owners_can_subscribe':
        return 'الاشتراك متاح لأصحاب الصالونات فقط';
    }
    switch (f.code) {
      case PaymentFailureCode.unauthenticated:
        return 'يرجى تسجيل الدخول أولاً';
      case PaymentFailureCode.permissionDenied:
        return 'غير مسموح لك بتنفيذ هذه العملية';
      case PaymentFailureCode.unavailable:
        return 'تعذر الاتصال. تحقق من الإنترنت وحاول مرة أخرى';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}
