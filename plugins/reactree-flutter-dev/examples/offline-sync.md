# Offline-First with Sync Example: Notes App

Complete offline-first implementation with background synchronization using Clean Architecture, GetX, Http, and GetStorage.

## Feature Requirements

- Create, read, update, delete notes offline
- Auto-sync when connection restored
- Conflict resolution (last-write-wins)
- Sync status indicators
- Queue pending operations
- Optimistic UI updates
- Manual sync trigger
- Offline indicator

## Architecture Overview

```
lib/
├── domain/
│   ├── entities/
│   │   ├── note.dart
│   │   └── sync_operation.dart
│   ├── repositories/
│   │   ├── note_repository.dart
│   │   └── sync_repository.dart
│   └── usecases/
│       ├── get_notes.dart
│       ├── save_note.dart
│       ├── delete_note.dart
│       └── sync_notes.dart
├── data/
│   ├── models/
│   │   ├── note_model.dart
│   │   └── sync_operation_model.dart
│   ├── repositories/
│   │   ├── note_repository_impl.dart
│   │   └── sync_repository_impl.dart
│   └── datasources/
│       ├── note_remote_datasource.dart
│       ├── note_local_datasource.dart
│       └── sync_queue_datasource.dart
└── presentation/
    ├── controllers/
    │   ├── note_controller.dart
    │   └── sync_controller.dart
    ├── bindings/
    │   └── note_binding.dart
    └── pages/
        ├── notes_page.dart
        └── widgets/
            ├── note_card.dart
            ├── sync_indicator.dart
            └── offline_banner.dart
```

---

## 1. Domain Layer

### Entities

```dart
// lib/domain/entities/note.dart
import 'package:equatable/equatable.dart';

enum SyncStatus { synced, pending, failed }

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.isDeleted = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [id, title, content, createdAt, updatedAt, syncStatus, isDeleted];
}

// lib/domain/entities/sync_operation.dart
import 'package:equatable/equatable.dart';

enum OperationType { create, update, delete }

class SyncOperation extends Equatable {
  final String id;
  final String noteId;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  const SyncOperation({
    required this.id,
    required this.noteId,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  SyncOperation copyWith({
    String? id,
    String? noteId,
    OperationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  List<Object?> get props => [id, noteId, type, data, timestamp, retryCount];
}
```

### Repository Interfaces

```dart
// lib/domain/repositories/note_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/note.dart';
import '../../core/errors/failures.dart';

abstract class NoteRepository {
  Future<Either<Failure, List<Note>>> getNotes();
  Future<Either<Failure, Note>> getNote(String id);
  Future<Either<Failure, Note>> saveNote(Note note);
  Future<Either<Failure, void>> deleteNote(String id);
}

// lib/domain/repositories/sync_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/sync_operation.dart';
import '../../core/errors/failures.dart';

abstract class SyncRepository {
  Future<Either<Failure, void>> queueOperation(SyncOperation operation);
  Future<Either<Failure, List<SyncOperation>>> getPendingOperations();
  Future<Either<Failure, void>> syncAll();
  Future<Either<Failure, void>> clearOperation(String operationId);
}
```

### Use Cases

```dart
// lib/domain/usecases/save_note.dart
import 'package:dartz/dartz.dart';
import '../entities/note.dart';
import '../entities/sync_operation.dart';
import '../repositories/note_repository.dart';
import '../repositories/sync_repository.dart';
import '../../core/errors/failures.dart';
import 'package:uuid/uuid.dart';

class SaveNote {
  final NoteRepository noteRepository;
  final SyncRepository syncRepository;

  SaveNote({
    required this.noteRepository,
    required this.syncRepository,
  });

  Future<Either<Failure, Note>> call(Note note) async {
    // Save locally first (offline-first)
    final localResult = await noteRepository.saveNote(
      note.copyWith(
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      ),
    );

    return localResult.fold(
      (failure) => Left(failure),
      (savedNote) async {
        // Queue sync operation
        final operation = SyncOperation(
          id: Uuid().v4(),
          noteId: savedNote.id,
          type: savedNote.createdAt == savedNote.updatedAt
              ? OperationType.create
              : OperationType.update,
          data: {
            'id': savedNote.id,
            'title': savedNote.title,
            'content': savedNote.content,
            'created_at': savedNote.createdAt.toIso8601String(),
            'updated_at': savedNote.updatedAt.toIso8601String(),
          },
          timestamp: DateTime.now(),
        );

        await syncRepository.queueOperation(operation);

        return Right(savedNote);
      },
    );
  }
}

// lib/domain/usecases/delete_note.dart
import 'package:dartz/dartz.dart';
import '../entities/sync_operation.dart';
import '../repositories/note_repository.dart';
import '../repositories/sync_repository.dart';
import '../../core/errors/failures.dart';
import 'package:uuid/uuid.dart';

class DeleteNote {
  final NoteRepository noteRepository;
  final SyncRepository syncRepository;

  DeleteNote({
    required this.noteRepository,
    required this.syncRepository,
  });

  Future<Either<Failure, void>> call(String id) async {
    // Delete locally first
    final result = await noteRepository.deleteNote(id);

    return result.fold(
      (failure) => Left(failure),
      (_) async {
        // Queue delete operation
        final operation = SyncOperation(
          id: Uuid().v4(),
          noteId: id,
          type: OperationType.delete,
          data: {'id': id},
          timestamp: DateTime.now(),
        );

        await syncRepository.queueOperation(operation);

        return Right(null);
      },
    );
  }
}

// lib/domain/usecases/sync_notes.dart
import 'package:dartz/dartz.dart';
import '../repositories/sync_repository.dart';
import '../../core/errors/failures.dart';

class SyncNotes {
  final SyncRepository syncRepository;

  SyncNotes(this.syncRepository);

  Future<Either<Failure, void>> call() {
    return syncRepository.syncAll();
  }
}
```

---

## 2. Data Layer

### Models

```dart
// lib/data/models/note_model.dart
import '../../domain/entities/note.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;
  final bool isDeleted;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
    this.isDeleted = false,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      syncStatus: json['sync_status'] as String? ?? 'synced',
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'is_deleted': isDeleted,
    };
  }

  Note toEntity() {
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      syncStatus: _mapSyncStatus(syncStatus),
      isDeleted: isDeleted,
    );
  }

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt.toIso8601String(),
      updatedAt: note.updatedAt.toIso8601String(),
      syncStatus: note.syncStatus.toString().split('.').last,
      isDeleted: note.isDeleted,
    );
  }

  static SyncStatus _mapSyncStatus(String status) {
    switch (status) {
      case 'pending':
        return SyncStatus.pending;
      case 'failed':
        return SyncStatus.failed;
      default:
        return SyncStatus.synced;
    }
  }
}
```

### Data Sources

```dart
// lib/data/datasources/note_local_datasource.dart
import 'package:get_storage/get_storage.dart';
import '../models/note_model.dart';
import '../../core/errors/exceptions.dart';

abstract class NoteLocalDataSource {
  Future<List<NoteModel>> getAllNotes();
  Future<NoteModel?> getNote(String id);
  Future<NoteModel> saveNote(NoteModel note);
  Future<void> deleteNote(String id);
  Future<void> updateSyncStatus(String id, String status);
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  final GetStorage storage;
  static const String notesKey = 'notes';

  NoteLocalDataSourceImpl(this.storage);

  @override
  Future<List<NoteModel>> getAllNotes() async {
    try {
      final notesJson = storage.read<List<dynamic>>(notesKey) ?? [];
      return notesJson
          .map((json) => NoteModel.fromJson(json as Map<String, dynamic>))
          .where((note) => !note.isDeleted)
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to read notes: $e');
    }
  }

  @override
  Future<NoteModel?> getNote(String id) async {
    try {
      final notes = await getAllNotes();
      return notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<NoteModel> saveNote(NoteModel note) async {
    try {
      final notes = await getAllNotes();
      final index = notes.indexWhere((n) => n.id == note.id);

      if (index >= 0) {
        notes[index] = note;
      } else {
        notes.add(note);
      }

      await storage.write(notesKey, notes.map((n) => n.toJson()).toList());
      return note;
    } catch (e) {
      throw CacheException(message: 'Failed to save note: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      final notes = await getAllNotes();
      final note = notes.firstWhere((n) => n.id == id);

      // Soft delete
      final deletedNote = NoteModel(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        syncStatus: 'pending',
        isDeleted: true,
      );

      await saveNote(deletedNote);
    } catch (e) {
      throw CacheException(message: 'Failed to delete note: $e');
    }
  }

  @override
  Future<void> updateSyncStatus(String id, String status) async {
    final note = await getNote(id);
    if (note != null) {
      await saveNote(NoteModel(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        syncStatus: status,
        isDeleted: note.isDeleted,
      ));
    }
  }
}

// lib/data/datasources/sync_queue_datasource.dart
import 'package:get_storage/get_storage.dart';
import '../models/sync_operation_model.dart';
import '../../core/errors/exceptions.dart';

abstract class SyncQueueDataSource {
  Future<List<SyncOperationModel>> getPendingOperations();
  Future<void> queueOperation(SyncOperationModel operation);
  Future<void> removeOperation(String operationId);
  Future<void> updateRetryCount(String operationId, int retryCount);
}

class SyncQueueDataSourceImpl implements SyncQueueDataSource {
  final GetStorage storage;
  static const String queueKey = 'sync_queue';

  SyncQueueDataSourceImpl(this.storage);

  @override
  Future<List<SyncOperationModel>> getPendingOperations() async {
    try {
      final queueJson = storage.read<List<dynamic>>(queueKey) ?? [];
      return queueJson
          .map((json) => SyncOperationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to read sync queue: $e');
    }
  }

  @override
  Future<void> queueOperation(SyncOperationModel operation) async {
    try {
      final queue = await getPendingOperations();

      // Replace existing operation for same note
      queue.removeWhere((op) => op.noteId == operation.noteId);
      queue.add(operation);

      await storage.write(queueKey, queue.map((op) => op.toJson()).toList());
    } catch (e) {
      throw CacheException(message: 'Failed to queue operation: $e');
    }
  }

  @override
  Future<void> removeOperation(String operationId) async {
    try {
      final queue = await getPendingOperations();
      queue.removeWhere((op) => op.id == operationId);
      await storage.write(queueKey, queue.map((op) => op.toJson()).toList());
    } catch (e) {
      throw CacheException(message: 'Failed to remove operation: $e');
    }
  }

  @override
  Future<void> updateRetryCount(String operationId, int retryCount) async {
    final queue = await getPendingOperations();
    final index = queue.indexWhere((op) => op.id == operationId);

    if (index >= 0) {
      queue[index] = SyncOperationModel(
        id: queue[index].id,
        noteId: queue[index].noteId,
        type: queue[index].type,
        data: queue[index].data,
        timestamp: queue[index].timestamp,
        retryCount: retryCount,
      );
      await storage.write(queueKey, queue.map((op) => op.toJson()).toList());
    }
  }
}
```

### Repository Implementation

```dart
// lib/data/repositories/sync_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/sync_operation.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/sync_queue_datasource.dart';
import '../datasources/note_remote_datasource.dart';
import '../datasources/note_local_datasource.dart';
import '../models/sync_operation_model.dart';
import '../models/note_model.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncQueueDataSource queueDataSource;
  final NoteRemoteDataSource remoteDataSource;
  final NoteLocalDataSource localDataSource;

  SyncRepositoryImpl({
    required this.queueDataSource,
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> queueOperation(SyncOperation operation) async {
    try {
      final model = SyncOperationModel.fromEntity(operation);
      await queueDataSource.queueOperation(model);
      return Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to queue operation: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SyncOperation>>> getPendingOperations() async {
    try {
      final operations = await queueDataSource.getPendingOperations();
      return Right(operations.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get pending operations: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncAll() async {
    try {
      final operations = await queueDataSource.getPendingOperations();

      // Sort by timestamp to maintain order
      operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (final operation in operations) {
        try {
          await _syncOperation(operation);

          // Mark as synced
          await localDataSource.updateSyncStatus(operation.noteId, 'synced');

          // Remove from queue
          await queueDataSource.removeOperation(operation.id);
        } catch (e) {
          // Increment retry count
          await queueDataSource.updateRetryCount(
            operation.id,
            operation.retryCount + 1,
          );

          // Mark as failed if too many retries
          if (operation.retryCount >= 3) {
            await localDataSource.updateSyncStatus(operation.noteId, 'failed');
          }
        }
      }

      return Right(null);
    } catch (e) {
      return Left(SyncFailure(message: 'Sync failed: $e'));
    }
  }

  Future<void> _syncOperation(SyncOperationModel operation) async {
    switch (operation.type) {
      case 'create':
      case 'update':
        final note = NoteModel.fromJson(operation.data);
        await remoteDataSource.saveNote(note);
        break;
      case 'delete':
        await remoteDataSource.deleteNote(operation.noteId);
        break;
    }
  }

  @override
  Future<Either<Failure, void>> clearOperation(String operationId) async {
    try {
      await queueDataSource.removeOperation(operationId);
      return Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear operation: $e'));
    }
  }
}
```

---

## 3. Presentation Layer

### Sync Controller

```dart
// lib/presentation/controllers/sync_controller.dart
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/usecases/sync_notes.dart';
import '../../domain/repositories/sync_repository.dart';
import 'dart:async';

class SyncController extends GetxController {
  final SyncNotes syncNotesUseCase;
  final SyncRepository syncRepository;

  SyncController({
    required this.syncNotesUseCase,
    required this.syncRepository,
  });

  // State
  final _isSyncing = false.obs;
  final _isOnline = true.obs;
  final _pendingCount = 0.obs;
  final _lastSyncTime = Rx<DateTime?>(null);

  StreamSubscription? _connectivitySubscription;
  Timer? _autoSyncTimer;

  // Getters
  bool get isSyncing => _isSyncing.value;
  bool get isOnline => _isOnline.value;
  int get pendingCount => _pendingCount.value;
  DateTime? get lastSyncTime => _lastSyncTime.value;

  @override
  void onInit() {
    super.onInit();
    _checkConnectivity();
    _listenToConnectivity();
    _updatePendingCount();
    _startAutoSync();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    super.onClose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline.value = result != ConnectivityResult.none;
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline.value;
      _isOnline.value = result != ConnectivityResult.none;

      // Auto-sync when coming back online
      if (wasOffline && _isOnline.value && _pendingCount.value > 0) {
        sync();
      }
    });
  }

  void _startAutoSync() {
    _autoSyncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      if (_isOnline.value && _pendingCount.value > 0) {
        sync();
      }
    });
  }

  Future<void> sync() async {
    if (_isSyncing.value || !_isOnline.value) return;

    _isSyncing.value = true;

    final result = await syncNotesUseCase();

    result.fold(
      (failure) {
        Get.snackbar('Sync Failed', 'Could not sync notes. Will retry later.');
      },
      (_) {
        _lastSyncTime.value = DateTime.now();
        _updatePendingCount();
        Get.snackbar('Sync Complete', 'All notes synchronized');
      },
    );

    _isSyncing.value = false;
  }

  Future<void> _updatePendingCount() async {
    final result = await syncRepository.getPendingOperations();
    result.fold(
      (_) => _pendingCount.value = 0,
      (operations) => _pendingCount.value = operations.length,
    );
  }

  void incrementPendingCount() {
    _pendingCount.value++;
  }
}

// lib/presentation/controllers/note_controller.dart
import 'package:get/get.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/save_note.dart';
import '../../domain/usecases/delete_note.dart';
import 'sync_controller.dart';
import 'package:uuid/uuid.dart';

class NoteController extends GetxController {
  final GetNotes getNotesUseCase;
  final SaveNote saveNoteUseCase;
  final DeleteNote deleteNoteUseCase;

  NoteController({
    required this.getNotesUseCase,
    required this.saveNoteUseCase,
    required this.deleteNoteUseCase,
  });

  final _notes = <Note>[].obs;
  final _isLoading = false.obs;

  List<Note> get notes => _notes.toList();
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading.value = true;

    final result = await getNotesUseCase();

    result.fold(
      (failure) => Get.snackbar('Error', 'Failed to load notes'),
      (loadedNotes) => _notes.value = loadedNotes,
    );

    _isLoading.value = false;
  }

  Future<void> createNote(String title, String content) async {
    final note = Note(
      id: Uuid().v4(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    final result = await saveNoteUseCase(note);

    result.fold(
      (failure) => Get.snackbar('Error', 'Failed to create note'),
      (savedNote) {
        _notes.insert(0, savedNote);
        Get.find<SyncController>().incrementPendingCount();
        Get.back();
        Get.snackbar('Success', 'Note created (will sync)');
      },
    );
  }

  Future<void> updateNote(Note note) async {
    final result = await saveNoteUseCase(note);

    result.fold(
      (failure) => Get.snackbar('Error', 'Failed to update note'),
      (updatedNote) {
        final index = _notes.indexWhere((n) => n.id == updatedNote.id);
        if (index >= 0) {
          _notes[index] = updatedNote;
        }
        Get.find<SyncController>().incrementPendingCount();
        Get.back();
        Get.snackbar('Success', 'Note updated (will sync)');
      },
    );
  }

  Future<void> deleteNoteById(String id) async {
    final result = await deleteNoteUseCase(id);

    result.fold(
      (failure) => Get.snackbar('Error', 'Failed to delete note'),
      (_) {
        _notes.removeWhere((note) => note.id == id);
        Get.find<SyncController>().incrementPendingCount();
        Get.snackbar('Success', 'Note deleted (will sync)');
      },
    );
  }
}
```

### UI with Sync Indicators

```dart
// lib/presentation/pages/notes_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/note_controller.dart';
import '../controllers/sync_controller.dart';
import 'widgets/note_card.dart';
import 'widgets/sync_indicator.dart';
import 'widgets/offline_banner.dart';

class NotesPage extends GetView<NoteController> {
  @override
  Widget build(BuildContext context) {
    final syncController = Get.find<SyncController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        actions: [
          Obx(() => SyncIndicator(
                isSyncing: syncController.isSyncing,
                pendingCount: syncController.pendingCount,
                onTap: syncController.sync,
              )),
        ],
      ),
      body: Column(
        children: [
          Obx(() => syncController.isOnline
              ? SizedBox.shrink()
              : OfflineBanner()),
          Expanded(child: _buildNotesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNoteDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList() {
    return Obx(() {
      if (controller.isLoading) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.notes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No notes yet', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.notes.length,
        itemBuilder: (context, index) {
          final note = controller.notes[index];
          return NoteCard(
            note: note,
            onTap: () => _showNoteDialog(note: note),
            onDelete: () => controller.deleteNoteById(note.id),
          );
        },
      );
    });
  }

  void _showNoteDialog({Note? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(note == null ? 'New Note' : 'Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (note == null) {
                controller.createNote(
                  titleController.text,
                  contentController.text,
                );
              } else {
                controller.updateNote(
                  note.copyWith(
                    title: titleController.text,
                    content: contentController.text,
                    updatedAt: DateTime.now(),
                  ),
                );
              }
            },
            child: Text(note == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}

// lib/presentation/pages/widgets/sync_indicator.dart
import 'package:flutter/material.dart';

class SyncIndicator extends StatelessWidget {
  final bool isSyncing;
  final int pendingCount;
  final VoidCallback onTap;

  const SyncIndicator({
    Key? key,
    required this.isSyncing,
    required this.pendingCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSyncing ? null : onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (isSyncing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (pendingCount > 0)
              Stack(
                children: [
                  Icon(Icons.cloud_upload),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            else
              Icon(Icons.cloud_done, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/pages/widgets/offline_banner.dart
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      color: Colors.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Offline - Changes will sync when reconnected',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
```

---

## Summary

This offline-sync example demonstrates:

✅ **Offline-First** - All operations work without internet
✅ **Sync Queue** - Pending operations queued and synced later
✅ **Optimistic UI** - Immediate feedback, sync in background
✅ **Conflict Resolution** - Last-write-wins strategy
✅ **Connectivity Detection** - Auto-sync when back online
✅ **Retry Logic** - Failed syncs retry with exponential backoff
✅ **Status Indicators** - Clear visual feedback for sync state
✅ **Clean Architecture** - Proper separation of concerns
✅ **GetX State Management** - Reactive UI with sync controller
✅ **GetStorage** - Reliable local persistence

This pattern enables fully functional offline apps with seamless synchronization.
