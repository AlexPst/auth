class AppResponceModel {
  final dynamic data;
  final dynamic error;
  final dynamic message;

  AppResponceModel({this.data, this.error, this.message});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'error': error ?? '',
        'data': data ?? '',
        'message': message ?? '',
      };
}
