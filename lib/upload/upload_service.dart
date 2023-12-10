import 'dart:collection';

import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/terminal/console.dart';

import '../config/project.dart';
import 'upload_request.dart';

abstract interface class UploadService {
  /// A `[a-z-_]` string to uniquely identify this service
  String get id;

  /// A user-friendly string used to identify this service
  String get name;

  /// Whether this service supports declaring relations
  /// between different projects
  bool get supportsRelations;

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

class UploadServices with Iterable<UploadService> {
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

  @override
  Iterator<UploadService> get iterator => _services.values.iterator;
}

extension ServiceChoosing on Iterable<UploadService> {
  Iterable<UploadService> choose(String nextMessage) => _ServiceChooserIterable(this, nextMessage);
}

class _ServiceChooserIterable with Iterable<UploadService> {
  final Iterable<UploadService> _services;
  final String _nextQuestion;

  _ServiceChooserIterable(this._services, this._nextQuestion);

  @override
  Iterator<UploadService> get iterator => _ServiceChooserIterator(_services, _nextQuestion);
}

class _ServiceChooserIterator implements Iterator<UploadService> {
  final List<UploadService> _services;
  UploadService? _current;
  final String _nextQuestion;

  _ServiceChooserIterator(Iterable<UploadService> services, this._nextQuestion) : _services = [...services];

  @override
  UploadService get current => _current!;

  @override
  bool moveNext() {
    if (_services.isEmpty || (_current != null && !console.ask(_nextQuestion))) return false;

    _services.remove(_current = _services.singleOrNull ??
        console.choose<UploadService>(
          _services,
          "Select platform",
          formatter: (entry) => entry.name,
          ephemeral: true,
        ));
    return true;
  }
}

/// An exception thrown by [UploadService.upload]
/// to communicate upload failure clearly to the user
class UploadException implements Exception {
  final String message;
  UploadException(this.message);
}
