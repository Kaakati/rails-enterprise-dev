# CRUD Feature Example: Task Management

Complete CRUD (Create, Read, Update, Delete) implementation for a task management feature using Clean Architecture, GetX, Http, and GetStorage.

## Feature Requirements

- List all tasks with pagination
- Create new tasks
- Update existing tasks (title, description, status)
- Delete tasks with confirmation
- Filter tasks by status (all, pending, completed)
- Search tasks by title
- Offline support with cache
- Pull-to-refresh

## Architecture Overview

```
lib/
├── domain/
│   ├── entities/
│   │   └── task.dart
│   ├── repositories/
│   │   └── task_repository.dart
│   └── usecases/
│       ├── get_tasks.dart
│       ├── create_task.dart
│       ├── update_task.dart
│       └── delete_task.dart
├── data/
│   ├── models/
│   │   └── task_model.dart
│   ├── repositories/
│   │   └── task_repository_impl.dart
│   └── datasources/
│       ├── task_remote_datasource.dart
│       └── task_local_datasource.dart
└── presentation/
    ├── controllers/
    │   └── task_controller.dart
    ├── bindings/
    │   └── task_binding.dart
    └── pages/
        ├── task_list_page.dart
        ├── task_form_page.dart
        └── widgets/
            ├── task_item.dart
            ├── task_filter_chip.dart
            └── empty_state.dart
```

---

## 1. Domain Layer

### Entity: Task

```dart
// lib/domain/entities/task.dart
import 'package:equatable/equatable.dart';

enum TaskStatus { pending, completed }

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, status, createdAt, updatedAt];
}
```

### Repository Interface

```dart
// lib/domain/repositories/task_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/task.dart';
import '../../core/errors/failures.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasks({
    TaskStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, Task>> getTask(String id);

  Future<Either<Failure, Task>> createTask({
    required String title,
    required String description,
  });

  Future<Either<Failure, Task>> updateTask(Task task);

  Future<Either<Failure, void>> deleteTask(String id);
}
```

### Use Cases

```dart
// lib/domain/usecases/get_tasks.dart
import 'package:dartz/dartz.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../core/errors/failures.dart';

class GetTasks {
  final TaskRepository repository;

  GetTasks(this.repository);

  Future<Either<Failure, List<Task>>> call({
    TaskStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) {
    return repository.getTasks(
      status: status,
      search: search,
      page: page,
      limit: limit,
    );
  }
}

// lib/domain/usecases/create_task.dart
import 'package:dartz/dartz.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../core/errors/failures.dart';

class CreateTask {
  final TaskRepository repository;

  CreateTask(this.repository);

  Future<Either<Failure, Task>> call({
    required String title,
    required String description,
  }) {
    if (title.trim().isEmpty) {
      return Future.value(Left(ValidationFailure(message: 'Title cannot be empty')));
    }

    if (title.length > 100) {
      return Future.value(Left(ValidationFailure(message: 'Title too long (max 100 characters)')));
    }

    return repository.createTask(title: title, description: description);
  }
}

// lib/domain/usecases/update_task.dart
import 'package:dartz/dartz.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../core/errors/failures.dart';

class UpdateTask {
  final TaskRepository repository;

  UpdateTask(this.repository);

  Future<Either<Failure, Task>> call(Task task) {
    if (task.title.trim().isEmpty) {
      return Future.value(Left(ValidationFailure(message: 'Title cannot be empty')));
    }

    return repository.updateTask(task);
  }
}

// lib/domain/usecases/delete_task.dart
import 'package:dartz/dartz.dart';
import '../repositories/task_repository.dart';
import '../../core/errors/failures.dart';

class DeleteTask {
  final TaskRepository repository;

  DeleteTask(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteTask(id);
  }
}
```

---

## 2. Data Layer

### Model

```dart
// lib/data/models/task_model.dart
import '../../domain/entities/task.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String createdAt;
  final String? updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // From JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // To Entity
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      status: status == 'completed' ? TaskStatus.completed : TaskStatus.pending,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
    );
  }

  // From Entity
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status == TaskStatus.completed ? 'completed' : 'pending',
      createdAt: task.createdAt.toIso8601String(),
      updatedAt: task.updatedAt?.toIso8601String(),
    );
  }
}
```

### Remote Data Source

```dart
// lib/data/datasources/task_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../../core/errors/exceptions.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  });
  Future<TaskModel> getTask(String id);
  Future<TaskModel> createTask(String title, String description);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  TaskRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<List<TaskModel>> getTasks({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['tasks'];
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch tasks',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<TaskModel> getTask(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return TaskModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          message: 'Failed to fetch task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<TaskModel> createTask(String title, String description) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'description': description,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        return TaskModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          message: 'Failed to create task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/tasks/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return TaskModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          message: 'Failed to update task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to delete task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }
}
```

### Local Data Source

```dart
// lib/data/datasources/task_local_datasource.dart
import 'package:get_storage/get_storage.dart';
import '../models/task_model.dart';
import '../../core/errors/exceptions.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getCachedTasks();
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<TaskModel?> getCachedTask(String id);
  Future<void> cacheTask(TaskModel task);
  Future<void> deleteTaskFromCache(String id);
  Future<void> clearCache();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final GetStorage storage;
  static const String tasksKey = 'cached_tasks';
  static const Duration cacheExpiry = Duration(hours: 1);

  TaskLocalDataSourceImpl(this.storage);

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    try {
      final cachedData = storage.read<Map<String, dynamic>>(tasksKey);

      if (cachedData == null) {
        throw CacheException(message: 'No cached tasks found');
      }

      final timestamp = DateTime.parse(cachedData['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > cacheExpiry) {
        await storage.remove(tasksKey);
        throw CacheException(message: 'Cache expired');
      }

      final List<dynamic> tasksJson = cachedData['tasks'];
      return tasksJson.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to read cached tasks: $e');
    }
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    try {
      await storage.write(tasksKey, {
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw CacheException(message: 'Failed to cache tasks: $e');
    }
  }

  @override
  Future<TaskModel?> getCachedTask(String id) async {
    try {
      final tasks = await getCachedTasks();
      return tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheTask(TaskModel task) async {
    try {
      final tasks = await getCachedTasks();
      final index = tasks.indexWhere((t) => t.id == task.id);

      if (index >= 0) {
        tasks[index] = task;
      } else {
        tasks.add(task);
      }

      await cacheTasks(tasks);
    } catch (e) {
      // If no cache exists, create new cache with single task
      await cacheTasks([task]);
    }
  }

  @override
  Future<void> deleteTaskFromCache(String id) async {
    try {
      final tasks = await getCachedTasks();
      tasks.removeWhere((task) => task.id == id);
      await cacheTasks(tasks);
    } catch (e) {
      // Ignore if cache doesn't exist
    }
  }

  @override
  Future<void> clearCache() async {
    await storage.remove(tasksKey);
  }
}
```

### Repository Implementation

```dart
// lib/data/repositories/task_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/task_remote_datasource.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Task>>> getTasks({
    TaskStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Try cache first for first page without filters
      if (page == 1 && status == null && (search == null || search.isEmpty)) {
        try {
          final cachedTasks = await localDataSource.getCachedTasks();
          // Return cached data immediately, refresh in background
          _refreshTasksInBackground(status, search, page, limit);
          return Right(cachedTasks.map((m) => m.toEntity()).toList());
        } catch (e) {
          // Cache miss or expired, fetch from network
        }
      }

      // Fetch from network
      final remoteTasks = await remoteDataSource.getTasks(
        status: status?.toString().split('.').last,
        search: search,
        page: page,
        limit: limit,
      );

      // Cache first page results
      if (page == 1 && status == null && (search == null || search.isEmpty)) {
        await localDataSource.cacheTasks(remoteTasks);
      }

      return Right(remoteTasks.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  void _refreshTasksInBackground(
    TaskStatus? status,
    String? search,
    int page,
    int limit,
  ) async {
    try {
      final remoteTasks = await remoteDataSource.getTasks(
        status: status?.toString().split('.').last,
        search: search,
        page: page,
        limit: limit,
      );
      await localDataSource.cacheTasks(remoteTasks);
    } catch (e) {
      // Silently fail background refresh
    }
  }

  @override
  Future<Either<Failure, Task>> getTask(String id) async {
    try {
      // Try cache first
      final cachedTask = await localDataSource.getCachedTask(id);
      if (cachedTask != null) {
        return Right(cachedTask.toEntity());
      }

      // Fetch from network
      final remoteTask = await remoteDataSource.getTask(id);
      await localDataSource.cacheTask(remoteTask);
      return Right(remoteTask.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> createTask({
    required String title,
    required String description,
  }) async {
    try {
      final taskModel = await remoteDataSource.createTask(title, description);

      // Add to cache
      await localDataSource.cacheTask(taskModel);

      return Right(taskModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final updatedModel = await remoteDataSource.updateTask(taskModel);

      // Update cache
      await localDataSource.cacheTask(updatedModel);

      return Right(updatedModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await remoteDataSource.deleteTask(id);

      // Remove from cache
      await localDataSource.deleteTaskFromCache(id);

      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Unexpected error: $e'));
    }
  }
}
```

---

## 3. Presentation Layer

### Controller

```dart
// lib/presentation/controllers/task_controller.dart
import 'package:get/get.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/delete_task.dart';

class TaskController extends GetxController {
  final GetTasks getTasksUseCase;
  final CreateTask createTaskUseCase;
  final UpdateTask updateTaskUseCase;
  final DeleteTask deleteTaskUseCase;

  TaskController({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
  });

  // State
  final _tasks = <Task>[].obs;
  final _isLoading = false.obs;
  final _isRefreshing = false.obs;
  final _isLoadingMore = false.obs;
  final _error = Rx<String?>(null);
  final _selectedStatus = Rx<TaskStatus?>(null);
  final _searchQuery = ''.obs;
  final _currentPage = 1.obs;
  final _hasMorePages = true.obs;

  // Getters
  List<Task> get tasks => _tasks.toList();
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get isLoadingMore => _isLoadingMore.value;
  String? get error => _error.value;
  TaskStatus? get selectedStatus => _selectedStatus.value;
  String get searchQuery => _searchQuery.value;
  bool get hasMorePages => _hasMorePages.value;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  Future<void> loadTasks({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;
    _error.value = null;
    _currentPage.value = 1;

    final result = await getTasksUseCase(
      status: _selectedStatus.value,
      search: _searchQuery.value.isEmpty ? null : _searchQuery.value,
      page: 1,
    );

    result.fold(
      (failure) => _error.value = _mapFailureToMessage(failure),
      (fetchedTasks) {
        _tasks.value = fetchedTasks;
        _hasMorePages.value = fetchedTasks.length >= 20;
      },
    );

    _isLoading.value = false;
  }

  Future<void> refreshTasks() async {
    _isRefreshing.value = true;
    await loadTasks(showLoading: false);
    _isRefreshing.value = false;
  }

  Future<void> loadMoreTasks() async {
    if (_isLoadingMore.value || !_hasMorePages.value) return;

    _isLoadingMore.value = true;
    _currentPage.value++;

    final result = await getTasksUseCase(
      status: _selectedStatus.value,
      search: _searchQuery.value.isEmpty ? null : _searchQuery.value,
      page: _currentPage.value,
    );

    result.fold(
      (failure) {
        _currentPage.value--;
        Get.snackbar('Error', _mapFailureToMessage(failure));
      },
      (fetchedTasks) {
        _tasks.addAll(fetchedTasks);
        _hasMorePages.value = fetchedTasks.length >= 20;
      },
    );

    _isLoadingMore.value = false;
  }

  Future<void> createNewTask(String title, String description) async {
    final result = await createTaskUseCase(title: title, description: description);

    result.fold(
      (failure) {
        Get.snackbar('Error', _mapFailureToMessage(failure));
      },
      (task) {
        _tasks.insert(0, task);
        Get.back();
        Get.snackbar('Success', 'Task created successfully');
      },
    );
  }

  Future<void> updateExistingTask(Task task) async {
    final result = await updateTaskUseCase(task);

    result.fold(
      (failure) {
        Get.snackbar('Error', _mapFailureToMessage(failure));
      },
      (updatedTask) {
        final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
        if (index >= 0) {
          _tasks[index] = updatedTask;
        }
        Get.back();
        Get.snackbar('Success', 'Task updated successfully');
      },
    );
  }

  Future<void> deleteExistingTask(String id) async {
    final result = await deleteTaskUseCase(id);

    result.fold(
      (failure) {
        Get.snackbar('Error', _mapFailureToMessage(failure));
      },
      (_) {
        _tasks.removeWhere((task) => task.id == id);
        Get.snackbar('Success', 'Task deleted successfully');
      },
    );
  }

  void toggleTaskStatus(Task task) {
    final updatedTask = task.copyWith(
      status: task.status == TaskStatus.pending
          ? TaskStatus.completed
          : TaskStatus.pending,
      updatedAt: DateTime.now(),
    );
    updateExistingTask(updatedTask);
  }

  void filterByStatus(TaskStatus? status) {
    _selectedStatus.value = status;
    loadTasks();
  }

  void search(String query) {
    _searchQuery.value = query;
    loadTasks();
  }

  void clearSearch() {
    _searchQuery.value = '';
    loadTasks();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message ?? 'Server error occurred';
    } else if (failure is NetworkFailure) {
      return 'No internet connection';
    } else if (failure is ValidationFailure) {
      return failure.message ?? 'Validation error';
    } else {
      return 'Unexpected error occurred';
    }
  }
}
```

### Binding

```dart
// lib/presentation/bindings/task_binding.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../controllers/task_controller.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    // Data sources
    Get.lazyPut<TaskRemoteDataSource>(
      () => TaskRemoteDataSourceImpl(
        client: http.Client(),
        baseUrl: 'https://api.example.com',
      ),
    );

    Get.lazyPut<TaskLocalDataSource>(
      () => TaskLocalDataSourceImpl(GetStorage()),
    );

    // Repository
    Get.lazyPut<TaskRepository>(
      () => TaskRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
      ),
    );

    // Use cases
    Get.lazyPut(() => GetTasks(Get.find()));
    Get.lazyPut(() => CreateTask(Get.find()));
    Get.lazyPut(() => UpdateTask(Get.find()));
    Get.lazyPut(() => DeleteTask(Get.find()));

    // Controller
    Get.lazyPut(
      () => TaskController(
        getTasksUseCase: Get.find(),
        createTaskUseCase: Get.find(),
        updateTaskUseCase: Get.find(),
        deleteTaskUseCase: Get.find(),
      ),
    );
  }
}
```

### UI Pages

```dart
// lib/presentation/pages/task_list_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import 'widgets/task_item.dart';
import 'widgets/task_filter_chip.dart';
import 'widgets/empty_state.dart';
import 'task_form_page.dart';

class TaskListPage extends GetView<TaskController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => TaskFormPage()),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              TaskFilterChip(
                label: 'All',
                isSelected: controller.selectedStatus == null,
                onTap: () => controller.filterByStatus(null),
              ),
              SizedBox(width: 8),
              TaskFilterChip(
                label: 'Pending',
                isSelected: controller.selectedStatus == TaskStatus.pending,
                onTap: () => controller.filterByStatus(TaskStatus.pending),
              ),
              SizedBox(width: 8),
              TaskFilterChip(
                label: 'Completed',
                isSelected: controller.selectedStatus == TaskStatus.completed,
                onTap: () => controller.filterByStatus(TaskStatus.completed),
              ),
            ],
          ),
        ));
  }

  Widget _buildTaskList() {
    return Obx(() {
      if (controller.isLoading) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.error!),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.loadTasks,
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (controller.tasks.isEmpty) {
        return EmptyState(
          message: 'No tasks yet',
          action: () => Get.to(() => TaskFormPage()),
          actionLabel: 'Create Task',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshTasks,
        child: ListView.builder(
          itemCount: controller.tasks.length + (controller.hasMorePages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.tasks.length) {
              // Load more indicator
              if (!controller.isLoadingMore) {
                controller.loadMoreTasks();
              }
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final task = controller.tasks[index];
            return TaskItem(
              task: task,
              onTap: () => Get.to(() => TaskFormPage(task: task)),
              onStatusToggle: () => controller.toggleTaskStatus(task),
              onDelete: () => _confirmDelete(task.id),
            );
          },
        ),
      );
    });
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Search Tasks'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter search term'),
          onSubmitted: (query) {
            Get.back();
            controller.search(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearSearch();
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteExistingTask(id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// lib/presentation/pages/task_form_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/task.dart';
import '../controllers/task_controller.dart';

class TaskFormPage extends GetView<TaskController> {
  final Task? task;

  TaskFormPage({this.task});

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    if (task != null) {
      _titleController.text = task!.title;
      _descriptionController.text = task!.description;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(task == null ? 'New Task' : 'Edit Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.length > 100) {
                  return 'Title too long (max 100 characters)';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveTask,
              child: Text(task == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    if (task == null) {
      controller.createNewTask(
        _titleController.text,
        _descriptionController.text,
      );
    } else {
      controller.updateExistingTask(
        task!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
        ),
      );
    }
  }
}
```

---

## 4. Testing

```dart
// test/domain/usecases/create_task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late CreateTask useCase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = CreateTask(mockRepository);
  });

  test('should return validation failure for empty title', () async {
    final result = await useCase(title: '', description: 'Test');

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('Should return failure'),
    );
    verifyNever(() => mockRepository.createTask(title: any(named: 'title'), description: any(named: 'description')));
  });

  test('should create task when validation passes', () async {
    final task = Task(
      id: '1',
      title: 'Test Task',
      description: 'Test Description',
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
    );

    when(() => mockRepository.createTask(title: 'Test Task', description: 'Test Description'))
        .thenAnswer((_) async => Right(task));

    final result = await useCase(title: 'Test Task', description: 'Test Description');

    expect(result.isRight(), true);
    verify(() => mockRepository.createTask(title: 'Test Task', description: 'Test Description')).called(1);
  });
}

// test/presentation/controllers/task_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get/get.dart';

void main() {
  late TaskController controller;
  late MockGetTasks mockGetTasks;
  late MockCreateTask mockCreateTask;
  late MockUpdateTask mockUpdateTask;
  late MockDeleteTask mockDeleteTask;

  setUp(() {
    mockGetTasks = MockGetTasks();
    mockCreateTask = MockCreateTask();
    mockUpdateTask = MockUpdateTask();
    mockDeleteTask = MockDeleteTask();

    controller = TaskController(
      getTasksUseCase: mockGetTasks,
      createTaskUseCase: mockCreateTask,
      updateTaskUseCase: mockUpdateTask,
      deleteTaskUseCase: mockDeleteTask,
    );
  });

  test('loadTasks should update tasks list on success', () async {
    final tasks = [
      Task(id: '1', title: 'Task 1', description: '', status: TaskStatus.pending, createdAt: DateTime.now()),
    ];

    when(() => mockGetTasks(status: null, search: null, page: 1))
        .thenAnswer((_) async => Right(tasks));

    await controller.loadTasks();

    expect(controller.tasks.length, 1);
    expect(controller.isLoading, false);
    expect(controller.error, null);
  });

  test('createNewTask should add task to list on success', () async {
    final task = Task(id: '1', title: 'New Task', description: '', status: TaskStatus.pending, createdAt: DateTime.now());

    when(() => mockCreateTask(title: 'New Task', description: ''))
        .thenAnswer((_) async => Right(task));

    await controller.createNewTask('New Task', '');

    expect(controller.tasks.length, 1);
    expect(controller.tasks.first.title, 'New Task');
  });
}
```

---

## Summary

This CRUD example demonstrates:

✅ **Complete Clean Architecture** - Clear separation of domain, data, and presentation layers
✅ **GetX State Management** - Reactive UI with proper controller lifecycle
✅ **Offline-First** - Cache-first strategy with background refresh
✅ **Pagination** - Load more pattern for large datasets
✅ **Search & Filter** - Dynamic query with status filtering
✅ **Error Handling** - Comprehensive error handling with user-friendly messages
✅ **Validation** - Input validation in use cases
✅ **Testing** - Unit tests for use cases and controller
✅ **Material Design** - Clean UI with pull-to-refresh and empty states

This pattern scales to any CRUD feature in Flutter applications.
