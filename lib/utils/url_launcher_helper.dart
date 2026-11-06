import 'package:url_launcher/url_launcher.dart';

/// Centralized utility helper for launching external URLs and phone dialer.
class UrlLauncherHelper {
  UrlLauncherHelper._();

  /// Launches the device dialer with the provided [phoneNumber].
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
