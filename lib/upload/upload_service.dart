import 'dart:collection';

import 'package:modrinth_api/modrinth_api.dart';

import '../config/project.dart';
import 'upload_request.dart';

abstract interface class UploadService {
  /// A `[a-z-_]` string to uniquely identify this service
  String get id;

  /// A user-friendly string used to identify this service
  String get name;

  /// Perform an upload for [project] as specified by [request]
  /// and return the URL of the resulting release
  ///
  /// The caller verifies before calling this method that
  /// [project] provides an id for this service *and* that
  /// this service supports the project type
  Future<Uri> upload(Project project, UploadRequest request);

  /// Verify that this service supports
  /// uploading/hosting projects of [type]
  bool supportsProjectType(ModrinthProjectType type);

  /// Test whether [projectId] corresponds to a valid
  /// project on the remote
  Future<bool> isProject(String projectId);

  /// Verify that this service has sufficient
  /// authentication to upload artifacts to the remote
  ///
  /// On success, return `null`, on failure, return an
  /// (ideally) user-friendly message describing the issues
  Future<String?> testAuth();
}

class UploadServices {
  final Map<String, UploadService> _services = {};
  UploadServices(List<UploadService> services) {
    for (final service in services) {
      if (_services.containsKey(service.id)) {
        throw ArgumentError("Duplicate service id '${service.id}'", "services");
      }

      _services[service.id] = service;
    }
  }

  /// Retrieve an unmodifiable view of a all
  /// services known to this provicder
  List<UploadService> get all => UnmodifiableListView(_services.values);

  /// Get the service identified by [id], or
  /// `null` if no such service is known to this provider
  UploadService? operator [](String id) => _services[id];
}

/// An exception thrown by [UploadService.upload]
/// to communicate upload failure clearly to the user
class UploadException implements Exception {
  final String message;
  UploadException(this.message);
}
