import 'dart:developer';
import 'dart:math' as Mh;

import 'package:frames_app/core/network/api_response.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../core/config/app_config.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;

  EmailService._internal();

  late final String _smtpServer;
  late final String _username;
  late final String _password;
  late final String _senderName;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _smtpServer = AppConfig().getConfig(['smtp', 'server']);
      _username = AppConfig().getConfig(['smtp', 'username']);
      _password = AppConfig().getConfig(['smtp', 'password']);
      _senderName = AppConfig().getConfig(['smtp', 'sender_name']);

      if (_smtpServer.isEmpty ||
          _username.isEmpty ||
          _password.isEmpty ||
          _senderName.isEmpty) {
        throw Exception('SMTP configuration is incomplete');
      }
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize EmailService: $e');
    }
  }

  String get generateOTP {
    String verificationCode = '';
    for (int i = 0; i < 6; i++) {
      verificationCode += (Mh.Random().nextInt(10)).toString();
    }
    return verificationCode;
  }

  Future<ApiResponse> sendVerificationCode(
      String userEmail, String verificationCode) async {
    if (!_isInitialized) {
      await initialize();
    }
    log(verificationCode, name: 'EmailService');

    final smtpServer = SmtpServer(
      _smtpServer,
      username: _username,
      password: _password,
    );

    final message = Message()
      ..from = Address(_username, _senderName)
      ..recipients.add(userEmail)
      ..subject = 'Verification Code :: ${DateTime.now()}'
      ..text = 'Your verification code is: $verificationCode';

    try {
      await send(message, smtpServer);
      return ApiResponse.success(data: {
        'otp': verificationCode,
      }, message: 'Verification code sent successfully');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
