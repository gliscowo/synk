import 'dart:collection';

import 'package:modrinth_api/modrinth_api.dart';

import '../config/project.dart';
import 'upload_request.dart';

abstract interface class UploadService {
  static final _registry = <String, UploadService>{};

  /// Globally register [service] under its [id] to be retrieved
  /// by [fromId] and listed by [registered]
  static void register(UploadService service) {
    if (_registry.containsKey(service.id)) {
      throw ArgumentError("An upload service with id '${service.id}' is already registered");
    }

    _registry[service.id] = service;
  }

  /// Fetch the upload service which identifies itself
  /// with [id] from the registry, given that it was
  /// previously registered
  static UploadService? fromId(String id) => _registry[id];

  /// Retrieve a view of all upload services currently
  /// in the registry
  static List<UploadService> get registered => UnmodifiableListView(_registry.values);

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

/// An exception thrown by [UploadService.upload]
/// to communicate upload failure clearly to the user
class UploadException implements Exception {
  final String message;
  UploadException(this.message);
}
