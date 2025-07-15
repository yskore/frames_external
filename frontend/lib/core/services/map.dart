import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/cubits/message_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class MapService {
  static Future<bool> openGoogleMapsNavigation(
    double lat,
    double lng, {
    BuildContext? context,
    WidgetRef? ref,
  }) async {
    try {
      // Try to launch using navigation URI (works on mobile)
      final url = Uri.parse('google.navigation:q=$lat,$lng&mode=w');
      if (await launchUrl(url)) {
        return true;
      }

      // Fallback to web URL if native app isn't available
      final webUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
      if (await launchUrl(webUrl)) {
        return true;
      }

      // Report failure
      if (ref != null) {
        context?.read<MessageCubit>().setError('Could not launch navigation');
      } else if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch navigation')),
        );
      }
      return false;
    } catch (e) {
      // Handle any exceptions
      if (ref != null) {
        context
            ?.read<MessageCubit>()
            .setError('Error launching navigation: $e');
      } else if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching navigation: $e')),
        );
      }
      return false;
    }
  }

  /// Opens map URL with the coordinates copied to clipboard
  static Future<void> shareLocationCoordinates(
    double lat,
    double lng, {
    required BuildContext context,
  }) async {
    try {
      final coords = '$lat,$lng';
      await Clipboard.setData(ClipboardData(text: coords));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates copied to clipboard')),
      );

      // Optional: Open the coordinates in a map
      final webUrl =
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$coords');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing location: $e')),
      );
    }
  }
}
