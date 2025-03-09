import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';



void sendVerificationCode(String userEmail, String verificationCode) async {
   // Generate a random 6-digit code

  final smtpServer = SmtpServer('smtp.gmail.com',
      username: 'frames.automated@gmail.com', password: 'hzacdczhgzghlbwe');

  final message = Message()
    ..from = Address('frames.automated@gmail.com', 'Frames App')
    ..recipients.add(userEmail)
    ..subject = 'Verification Code :: ${DateTime.now()}'
    ..text = 'Your verification code is: $verificationCode';

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Message not sent. \n' + e.toString());
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}