class SkarbException {
  final String message;
  final String code;

  SkarbException(this.message, this.code);

  SkarbException.fromJson(Map<dynamic, dynamic> json)
      : message = json['message'],
        code = json['errorCode'];

  @override
  String toString() {
    return 'SkarbException{message: $message, code: $code}';
  }
}

class SkarbPaymentPendingException extends SkarbException {
  SkarbPaymentPendingException()
      : super('The payment is pending', 'PAYMENT_PENDING');
}
