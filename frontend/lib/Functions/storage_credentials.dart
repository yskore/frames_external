import 'dart:async';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:path/path.dart' as path;

final _credentials = auth.ServiceAccountCredentials.fromJson({
  "type": "service_account",
  "project_id": "x-fabric-419423",
  "private_key_id": "1017e7fb19824acd64f6f0aa7cb0e6bc4ce8063d",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDuE91VNcxNX6hx\ngxThW/fC4qPZ7zESUVbYYK9zBShRKQ0g1rjSS13cIgkjafoi6MwroA723R8zqX+W\nCBpBS2M1HDi5R4TXsRVxK/i4q6p17dxCnoB+LM9L8estna9YRttEJbvZbhDCdPZX\npa5EQ/C2WsR1GR3IZN86l8oQVLhjHLB5/BtuQOxBkvep5TSwhEXwKdGBX3ILA8/2\nbj14Wdjiq315HVbvUu1lNXJn83JwfuRljEbWvqIU/0b6lXwpEEwCu36Bf/wdB4nu\ngY0o6NQ1LxogH7YWoNwG5aWzrTnsej8jdb7Yb2PSc28ZGV4E3AqFjzJKmuonk1E+\n56e22WG5AgMBAAECggEAFQNy1zkK4c9uJiq8NpHwAecQMEWw7p14TVvnUH8lilhV\nvM7G/GTDkZD9fn81oUwr7TPQ7lAhF2XACaWIb7fwNzlY9l2OJ52NN3J6nw4j2wnW\nFZk43SomV90v9VRELEYAx3iPJodU+lzpe133zjWy8t17FpzTaKMiouDP6HYZ2kF7\n6DZh/CQbLL93DghIiqO7/VAJAPgQohbTWLdLftBPj9jeQ1lZoiV7OlNXBoPCsUGF\nIJd51BGRVb7WnmVmePngjcrP+kuykdykIzMxkw8dm+MxaMfhUAsBMCwJ/W40xi1o\nxL6EZOQctjtDqkdoMfrIHCRLSKIgXGWXNMAuDgIbyQKBgQD8473n4il1zc5B8bGJ\nfc9Pm6iZTcU1mTP/4ff/fYL3gWK/LzWUkcd085ocpryYvFvQWmD/4SLwGKVHVLPe\n2Rurl7pj/HQ3XdDkkZtDzUj+QY87xUnzrD9rPgEJjOq5MM2VXZXgplE/QOJ3Szcx\nEkD8ADgkzNX1pFYgE+9EzwVk5QKBgQDxAXwsZhf61Df2M3C9MQ6kRurBrutaa9xz\nZ9WVLo+zJb2TJsLIsbcL2Px7400Oz3SxIEZSPiYRCMH8DYdLHKWsGBiizUlVukUB\n0jVFkBToeQV9ZAFeqlxt7CINctmBzOd1vjScygbhtFShFRD/8bMPzsPtHv+pRq0z\nMEOQai1wRQKBgQD0m9kR1SmjQBmUoZLHWgDPkNHIz3fEu1aX2FvILgAjJWx9Xs2l\n0kgqcIKN2h2sYu0wIGuYtYzUzhH4aA6/rCLenBl3IzbKYx1uKQUU1RkYjhNcjh1U\n7DQ/qC7arQpRbMo+AtK5BEasNzeWihNtjKl81z13IwaF3ppL1txmIxSlnQKBgFHv\nqFDL8PEk/1WjzXt01z6AocVxe7CFJTDTJ2kNqGtGtHn33pcu3EWZ4tUXxRX47/pc\nN6w0VurJqHHSA6JEvgqRMqb+1iTgLB/fYJ8iygjzRCuKOXD+yGfStQ0Pc+VOTY7Z\nOLfpc4d+sJsHN31cpf0E1dWjCVZ6od3aVc4eWw5lAoGATlMKgFZN9KqLMM7UJ5JQ\nWArc7FKhzC3LXc7z/Ye5i0YH162i8FZ12RhVFTM88vcZVnw4c3wNoBj9ApazCevP\nmWX8iAdnER0um3TVOY+7yND3xUKGZwnzNM0ZSKsGr4gwijHZp5Zjhlet/DCzXCqj\n71CrAcnHzbtrJG1wPmtvBIQ=\n-----END PRIVATE KEY-----\n",
  "client_email": "full-bucket-access@x-fabric-419423.iam.gserviceaccount.com",
  "client_id": "115786911957504702543",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/full-bucket-access%40x-fabric-419423.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
});

final _scopes = [storage.StorageApi.devstorageFullControlScope];

Future<storage.StorageApi> authenticate() async {
  var httpClient = await auth.clientViaServiceAccount(_credentials, _scopes);
  return storage.StorageApi(httpClient);
}



Future<String> uploadImage(File imageFile, String bucketName, String folderName) async {
  final api = await authenticate();

  final objectName = '$folderName/${path.basename(imageFile.path)}';
  final media = storage.Media(imageFile.openRead(), imageFile.lengthSync());

  await api.objects.insert(
    storage.Object()..name = objectName,
    bucketName,
    uploadMedia: media,
  );

  return 'https://storage.googleapis.com/$bucketName/$objectName'; }

  // The variable to store the URL of the uploaded image
String tempPieceImage = '';

// The variable to store the name of the old image
var oldImageName ;

  Future<String> piece_image_upload_url(File imageFile, String bucketName, String folderName) async {
  final client = await auth.clientViaServiceAccount(_credentials, _scopes);
  final storageApi = storage.StorageApi(client);

  // Delete the old image if it exists
  if (oldImageName != null) {
    await storageApi.objects.delete(bucketName, oldImageName);
    oldImageName = null;
  }

  // Upload the new image
  final media = storage.Media(imageFile.openRead(), imageFile.lengthSync());
  final response = await storageApi.objects.insert(
    storage.Object.fromJson({'name': '$folderName/${imageFile.path.split('/').last}'}),
    bucketName,
    uploadMedia: media,
  );

  // Store the URL of the uploaded image
  tempPieceImage = response.mediaLink.toString();

  // Store the name of the uploaded image
  oldImageName = response.name;

  client.close();

  return tempPieceImage;
}

