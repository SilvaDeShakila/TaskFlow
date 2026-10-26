import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/task.dart';
import '../services/task_storage.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_tile.dart';

enum TaskFilter { all, active, completed }
enum TaskSort { newest, priorityHighFirst, titleAZ }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskStorage _storage = TaskStorage();
  final List<Task> _tasks = [];

  String _currentSection = 'Dashboard';
  TaskFilter _filter = TaskFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  TaskSort _sortOrder = TaskSort.newest;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final savedTasks = await _storage.loadTasks();

      if (!mounted) return;

      setState(() {
        _tasks
          ..clear()
          ..addAll(savedTasks);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Could not load saved tasks.');
    }
  }

  Future<void> _saveTasks() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _storage.saveTasks(_tasks);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save tasks. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      } else {
        _isSaving = false;
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openTaskDialog({Task? task}) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => AddTaskDialog(task: task),
    );

    if (!mounted || result == null) return;

    setState(() {
      final index = _tasks.indexWhere((item) => item.id == result.id);

      if (index >= 0) {
        _tasks[index] = result;
      } else {
        _tasks.insert(0, result);
      }
    });

    await _saveTasks();
  }

  Future<void> _toggleTask(Task task, bool? completed) async {
    if (completed == null) return;

    setState(() => task.isCompleted = completed);
    await _saveTasks();
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _tasks.removeWhere((item) => item.id == task.id));
    await _saveTasks();
    _showMessage('Task deleted.');
  }

  List<Task> get _filteredTasks {
    List<Task> result;

    switch (_filter) {
      case TaskFilter.active:
        result = _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.completed:
        result = _tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.all:
        result = List<Task>.from(_tasks);
    }

    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((task) {
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query);
      }).toList();
    }

    switch (_sortOrder) {
      case TaskSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSort.priorityHighFirst:
        int priorityRank(TaskPriority priority) {
          switch (priority) {
            case TaskPriority.high:
              return 0;
            case TaskPriority.medium:
              return 1;
            case TaskPriority.low:
              return 2;
          }
        }

        result.sort((a, b) {
          final priorityComparison =
              priorityRank(a.priority).compareTo(priorityRank(b.priority));

          if (priorityComparison != 0) return priorityComparison;
          return b.createdAt.compareTo(a.createdAt);
        });
      case TaskSort.titleAZ:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }

    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _completedCount =>
      _tasks.where((task) => task.isCompleted).length;

  int get _activeCount => _tasks.length - _completedCount;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskDialog(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add new task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE7E9FF),
              Color(0xFFF2F1FF),
              Color(0xFFEAF0FF),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (desktop) _buildSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              desktop ? 30 : 18, 18,
                              desktop ? 30 : 18, 8,
                            ),
                            child: Row(
                              children: [
                                if (!desktop) ...[
                                  Container(
                                    width: 43,
                                    height: 43,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF5148E8),
                                          Color(0xFF8878FF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 27,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        desktop ? 'YOUR WORKSPACE' : 'TASKFLOW',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.6,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        desktop ? 'Dashboard' : 'My productivity space',
                                        style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Refresh tasks',
                                  onPressed: _loadTasks,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD9D8FA),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'SD',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                desktop ? 30 : 16, 14,
                                desktop ? 30 : 16, 110,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1050,
                                  ),
                                  child: _currentSection == 'Profile'
                                      ? _buildProfileContent()
                                      : _buildDashboardContent(desktop: desktop),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 235,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF191B46),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25215E).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(5, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF766BFF), Color(0xFFA394FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.done_all_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TaskFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 38),
          const Padding(
            padding: EdgeInsets.only(left: 10, bottom: 12),
            child: Text(
              'WORKSPACE',
              style: TextStyle(
                color: Color(0xFF989BC8),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _sidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            selected: _currentSection == 'Dashboard',
            onTap: () => setState(() => _currentSection = 'Dashboard'),
          ),
          _sidebarItem(
            icon: Icons.checklist_rounded,
            label: 'My Tasks',
            selected: _currentSection == 'My Tasks',
            onTap: () => setState(() => _currentSection = 'My Tasks'),
          ),
          _sidebarItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            selected: _currentSection == 'Profile',
            onTap: () => setState(() => _currentSection = 'Profile'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8175FF), Color(0xFFB2A7FF)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'SD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shakila D.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Personal workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFB4B6D8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? Colors.white : Colors.white70, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDashboardContent({required bool desktop}) {
    final filteredTasks = _filteredTasks;
    final total = _tasks.length;
    final completed = _completedCount;
    final progress = total == 0 ? 0.0 : completed / total;
    final percentage = (progress * 100).round();
    final highPriority = _tasks.where(
      (task) => task.priority == TaskPriority.high && !task.isCompleted,
    ).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWelcomeCard(
          total: total,
          completed: completed,
          progress: progress,
          percentage: percentage,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatCard(
              label: 'Total tasks',
              count: total,
              icon: Icons.checklist_rounded,
              color: const Color(0xFF5148E8),
              background: const Color(0xFFE7E5FF),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              label: 'Active',
              count: _activeCount,
              icon: Icons.hourglass_top_rounded,
              color: const Color(0xFF2676D9),
              background: const Color(0xFFE2EEFF),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              label: 'Completed',
              count: completed,
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF159B79),
              background: const Color(0xFFE0F7EF),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(desktop ? 22 : 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDADDF5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B3487).withValues(alpha: 0.055),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5148E8), Color(0xFF8978FF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Keep your day organized',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEAFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredTasks.length} tasks',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF1F2FF),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFE1E3F6)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildFilter('All', TaskFilter.all),
                  const SizedBox(width: 7),
                  _buildFilter('Active', TaskFilter.active),
                  const SizedBox(width: 7),
                  _buildFilter('Completed', TaskFilter.completed),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: AppTheme.mutedColor,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedColor,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<TaskSort>(
                    value: _sortOrder,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TaskSort.newest,
                        child: Text('Newest first'),
                      ),
                      DropdownMenuItem(
                        value: TaskSort.priorityHighFirst,
                        child: Text('High priority first'),
                      ),
                      DropdownMenuItem(
                        value: TaskSort.titleAZ,
                        child: Text('Title A–Z'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortOrder = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredTasks.isEmpty)
                SizedBox(height: 240, child: _buildEmptyState())
              else
                ...filteredTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskTile(
                      task: task,
                      onCompletionChanged: (value) =>
                          _toggleTask(task, value),
                      onEdit: () => _openTaskDialog(task: task),
                      onDelete: () => _deleteTask(task),
                    ),
                  ),
                ),
              if (_isSaving) ...[
                const SizedBox(height: 6),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (highPriority > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFFD97735),
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '$highPriority high-priority '
                          '${highPriority == 1 ? 'task needs' : 'tasks need'} '
                          'your attention.',
                          style: const TextStyle(
                            color: Color(0xFF98521E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildProfileContent() {
    final total = _tasks.length;
    final completed = _completedCount;
    final progress = total == 0 ? 0.0 : completed / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal workspace and task activity.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF20243A), Color(0xFF3930B8), Color(0xFF635BFF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  child: Text(
                    'SD',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shakila D.',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Personal Workspace',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 16),
                const Chip(
                  label: Text('TaskFlow Member'),
                  avatar: Icon(Icons.verified_user_outlined, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildStatCard(label: 'Total Tasks', count: total, icon: Icons.checklist_rounded, color: const Color(0xFF635BFF), background: const Color(0xFFE8E6FF))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(label: 'Completed', count: completed, icon: Icons.task_alt_rounded, color: const Color(0xFF16A34A), background: const Color(0xFFDCFCE7))),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completion Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppTheme.softPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${(progress * 100).round()}% of your tasks completed'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TaskFlow To-Do List', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Tasks are saved locally on this device.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildWelcomeCard({
    required int total,
    required int completed,
    required double progress,
    required int percentage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF20243A),
            Color(0xFF3930B8),
            Color(0xFF635BFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay on track ✨',
                      style: TextStyle(
                        color: AppTheme.cardColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Small steps lead to big achievements.',
                      style: TextStyle(
                        color: Color(0xFFE8E6FF),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.cardColor,
                  size: 27,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? 'Ready when you are!'
                      : '$completed of $total tasks completed',
                  style: const TextStyle(
                    color: AppTheme.cardColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: AppTheme.cardColor,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.fromLTRB(9, 9, 7, 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textColor.withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 11),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter(String label, TaskFilter filter) {
    final selected = _filter == filter;

    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = filter),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.cardColor,
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : AppTheme.mutedColor,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected
              ? AppTheme.primaryColor
              : const Color(0xFFE8E9F2),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5),
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = switch (_filter) {
      TaskFilter.all => 'Nothing on your list yet',
      TaskFilter.active => 'No active tasks',
      TaskFilter.completed => 'No completed tasks yet',
    };

    final subtitle = switch (_filter) {
      TaskFilter.all => 'Add your first task and start planning.',
      TaskFilter.active => 'You have no tasks left to work on.',
      TaskFilter.completed => 'Completed tasks will appear here.',
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(23),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checklist_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.mutedColor,
              ),
            ),
            if (_filter == TaskFilter.all) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _openTaskDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create your first task'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}











