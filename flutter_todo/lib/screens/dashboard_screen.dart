import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../services/auth_service.dart';
import '../services/todo_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum FilterTab { all, active, completed }
enum SortType { newest, priority, dueDate }

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<TodoModel> _todos = [];
  bool _isLoading = true;
  String _userEmail = '';
  FilterTab _filter = FilterTab.all;
  SortType _sortType = SortType.newest;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _filter = FilterTab.values[_tabController.index]);
      }
    });
    final decoded = JwtDecoder.decode(widget.token);
    _userEmail = decoded['email'] ?? '';
    _loadTodos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Lọc + tìm kiếm + sắp xếp
  List<TodoModel> get _filtered {
    var list = _todos.where((t) {
      final matchFilter = _filter == FilterTab.all
          ? true
          : _filter == FilterTab.active
              ? !t.isCompleted
              : t.isCompleted;
      final matchSearch = _searchQuery.isEmpty
          ? true
          : t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();

    // Sắp xếp
    switch (_sortType) {
      case SortType.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.priority:
        const order = {'high': 0, 'medium': 1, 'low': 2};
        list.sort((a, b) =>
            (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1));
        break;
      case SortType.dueDate:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
    }
    return list;
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    try {
      final todos = await TodoService.getTodos();
      setState(() { _todos = todos; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Không thể tải: $e');
    }
  }

  Future<void> _deleteTodo(String id) async {
    try {
      await TodoService.deleteTodo(id);
      setState(() => _todos.removeWhere((t) => t.id == id));
      _showSnack('🗑️ Đã xóa todo', const Color(0xFF533483));
    } catch (e) { _showError('$e'); }
  }

  Future<void> _toggleTodo(String id) async {
    try {
      final updated = await TodoService.toggleTodo(id);
      setState(() {
        final idx = _todos.indexWhere((t) => t.id == id);
        if (idx != -1) _todos[idx] = updated;
      });
    } catch (e) { _showError('$e'); }
  }

  Future<void> _deleteCompleted() async {
    final completed = _todos.where((t) => t.isCompleted).length;
    if (completed == 0) {
      _showSnack('Không có todo đã hoàn thành', Colors.orange);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Xóa tất cả đã hoàn thành?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Sẽ xóa $completed todo.',
            style: const TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final count = await TodoService.deleteCompleted();
      setState(() => _todos.removeWhere((t) => t.isCompleted));
      _showSnack('✅ Đã xóa $count todo hoàn thành', const Color(0xFF533483));
    } catch (e) { _showError('$e'); }
  }

  Future<void> _logout() async {
    await AuthService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE94560)));

  void _showSnack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  // ─── Todo Dialog (Thêm / Sửa) ───────────────────────────────────────────
  Future<void> _showTodoDialog({TodoModel? todo}) async {
    final titleCtrl = TextEditingController(text: todo?.title ?? '');
    final descCtrl = TextEditingController(text: todo?.description ?? '');
    String priority = todo?.priority ?? 'medium';
    DateTime? dueDate = todo?.dueDate;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            todo == null ? '✨ Thêm Todo Mới' : '✏️ Chỉnh Sửa Todo',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Tiêu đề
                TextFormField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v == null || v.isEmpty ? 'Nhập tiêu đề' : null,
                  decoration: _dlgDeco('Tiêu đề *', Icons.title),
                ),
                const SizedBox(height: 12),
                // Mô tả
                TextFormField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: _dlgDeco('Mô tả (tuỳ chọn)', Icons.notes),
                ),
                const SizedBox(height: 12),

                // Ưu tiên
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mức ưu tiên', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    for (final p in ['low', 'medium', 'high'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setS(() => priority = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: priority == p
                                    ? _priorityColor(p).withOpacity(0.25)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: priority == p
                                      ? _priorityColor(p)
                                      : Colors.white12,
                                  width: priority == p ? 2 : 1,
                                ),
                              ),
                              child: Column(children: [
                                Icon(_priorityIcon(p), color: _priorityColor(p), size: 18),
                                const SizedBox(height: 3),
                                Text(_priorityLabel(p),
                                    style: TextStyle(
                                        color: priority == p ? _priorityColor(p) : Colors.white38,
                                        fontSize: 10, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ]),
                const SizedBox(height: 12),

                // Hạn chót
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: Color(0xFFE94560)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setS(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dueDate != null
                              ? '📅 ${DateFormat('dd/MM/yyyy').format(dueDate!)}'
                              : 'Chọn hạn chót (tuỳ chọn)',
                          style: TextStyle(
                              color: dueDate != null ? Colors.white : Colors.white38,
                              fontSize: 13),
                        ),
                      ),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => setS(() => dueDate = null),
                          child: const Icon(Icons.close, color: Colors.white38, size: 16),
                        ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setS(() => saving = true);
                try {
                  if (todo == null) {
                    final newTodo = await TodoService.createTodo(
                        titleCtrl.text.trim(), descCtrl.text.trim(),
                        priority: priority, dueDate: dueDate);
                    setState(() => _todos.insert(0, newTodo));
                  } else {
                    final updated = await TodoService.updateTodo(
                        todo.id, titleCtrl.text.trim(), descCtrl.text.trim(),
                        priority: priority, dueDate: dueDate,
                        clearDueDate: dueDate == null && todo.dueDate != null);
                    setState(() {
                      final idx = _todos.indexWhere((t) => t.id == todo.id);
                      if (idx != -1) _todos[idx] = updated;
                    });
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnack(todo == null ? '✅ Đã thêm' : '✅ Đã cập nhật',
                      const Color(0xFF533483));
                } catch (e) {
                  setS(() => saving = false);
                  _showError('$e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(todo == null ? 'Thêm' : 'Lưu',
                      style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dlgDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
    prefixIcon: Icon(icon, color: Colors.white38, size: 18),
    filled: true, fillColor: Colors.white.withOpacity(0.07),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE94560))),
    errorStyle: const TextStyle(color: Color(0xFFE94560)),
  );

  // ─── Priority helpers ────────────────────────────────────────────────────
  Color _priorityColor(String p) => p == 'high'
      ? const Color(0xFFE94560) : p == 'medium' ? Colors.orange : Colors.green;
  IconData _priorityIcon(String p) => p == 'high'
      ? Icons.keyboard_double_arrow_up : p == 'medium'
      ? Icons.drag_handle : Icons.keyboard_double_arrow_down;
  String _priorityLabel(String p) =>
      p == 'high' ? 'Cao' : p == 'medium' ? 'Trung bình' : 'Thấp';

  // ─── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final completedCount = _todos.where((t) => t.isCompleted).length;
    final totalCount = _todos.length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            actions: [
              // Sort button
              PopupMenuButton<SortType>(
                icon: const Icon(Icons.sort, color: Colors.white70),
                color: const Color(0xFF1A1A2E),
                onSelected: (v) => setState(() => _sortType = v),
                itemBuilder: (_) => [
                  _menuItem(SortType.newest, Icons.access_time, 'Mới nhất'),
                  _menuItem(SortType.priority, Icons.flag, 'Ưu tiên'),
                  _menuItem(SortType.dueDate, Icons.calendar_today, 'Hạn chót'),
                ],
              ),
              // Delete completed
              IconButton(
                icon: const Icon(Icons.playlist_remove, color: Colors.white70),
                tooltip: 'Xóa đã hoàn thành',
                onPressed: _deleteCompleted,
              ),
              // Logout
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                onPressed: _logout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Color(0xFFE94560), Color(0xFF533483)]),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Xin chào! 👋',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white54, fontSize: 11)),
                                Text(
                                  _userEmail,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedCount/$totalCount hoàn thành',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 11),
                          ),
                          Text(
                            totalCount > 0
                                ? '${(completedCount / totalCount * 100).toInt()}%'
                                : '0%',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFFE94560),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: totalCount > 0
                              ? completedCount / totalCount
                              : 0,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE94560)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFE94560),
              labelColor: const Color(0xFFE94560),
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Tất cả (${_todos.length})'),
                Tab(
                    text:
                        'Đang làm (${_todos.where((t) => !t.isCompleted).length})'),
                Tab(
                    text:
                        'Xong (${_todos.where((t) => t.isCompleted).length})'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            // Thanh tìm kiếm được đặt ở đây - Luôn nằm dưới Tab và không bị chồng
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                height: 45,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm công việc của bạn...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE94560), width: 1),
                    ),
                  ),
                ),
              ),
            ),
            // Danh sách Todo
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                  : filtered.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: _loadTodos,
                          color: const Color(0xFFE94560),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _buildCard(filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTodoDialog(),
        backgroundColor: const Color(0xFFE94560),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Thêm', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  PopupMenuItem<SortType> _menuItem(SortType type, IconData icon, String label) =>
      PopupMenuItem(
        value: type,
        child: Row(children: [
          Icon(icon, color: _sortType == type ? const Color(0xFFE94560) : Colors.white54, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: _sortType == type ? const Color(0xFFE94560) : Colors.white70)),
        ]),
      );

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, size: 65, color: Colors.white.withOpacity(0.12)),
      const SizedBox(height: 14),
      Text(
        _searchQuery.isNotEmpty ? 'Không tìm thấy kết quả' : 'Chưa có todo nào',
        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 15),
      ),
      if (_searchQuery.isEmpty)
        Text('Nhấn + để thêm công việc mới',
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
    ]),
  );

  Widget _buildCard(TodoModel todo) {
    final overdue = todo.isOverdue;
    final days = todo.daysUntilDue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: Key(todo.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showTodoDialog(todo: todo),
              backgroundColor: const Color(0xFF533483),
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Sửa',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
            SlidableAction(
              onPressed: (_) => _deleteTodo(todo.id),
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Xóa',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: overdue
                  ? const Color(0xFFE94560).withOpacity(0.5)
                  : todo.isCompleted
                      ? const Color(0xFF533483).withOpacity(0.3)
                      : Colors.white.withOpacity(0.06),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: GestureDetector(
              onTap: () => _toggleTodo(todo.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: todo.isCompleted ? const Color(0xFF533483) : Colors.transparent,
                  border: Border.all(
                    color: todo.isCompleted ? const Color(0xFF533483) : Colors.white38,
                    width: 2,
                  ),
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 15) : null,
              ),
            ),
            title: Row(children: [
              Expanded(
                child: Text(todo.title,
                  style: GoogleFonts.poppins(
                    color: todo.isCompleted ? Colors.white38 : Colors.white,
                    fontWeight: FontWeight.w500, fontSize: 14,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _priorityColor(todo.priority).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _priorityColor(todo.priority).withOpacity(0.4)),
                ),
                child: Icon(_priorityIcon(todo.priority),
                    color: _priorityColor(todo.priority), size: 12),
              ),
            ]),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(todo.description,
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
              if (todo.dueDate != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(
                    overdue ? Icons.warning_amber_rounded : Icons.calendar_today,
                    size: 11,
                    color: overdue ? const Color(0xFFE94560) : Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    overdue
                        ? '⚠️ Quá hạn ${DateFormat('dd/MM/yyyy').format(todo.dueDate!)}'
                        : days == 0
                            ? '📅 Hôm nay!'
                            : days == 1
                                ? '📅 Ngày mai'
                                : '📅 ${DateFormat('dd/MM/yyyy').format(todo.dueDate!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: overdue ? const Color(0xFFE94560) : Colors.white38,
                      fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
