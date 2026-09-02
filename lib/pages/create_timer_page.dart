import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/cards.dart';
import '../widgets/duration_picker_card.dart';

class CreateTimerPage extends StatefulWidget {
  const CreateTimerPage({
    super.key,
    required this.onSave,
  });

  final Future<void> Function(String name, int seconds) onSave;

  @override
  State<CreateTimerPage> createState() => _CreateTimerPageState();
}

class _CreateTimerPageState extends State<CreateTimerPage> {
  final TextEditingController _controller = TextEditingController();
  int _seconds = 5 * 60;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: '创建倒计时',
      canSave: true,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('选择倒计时时长', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          DurationPickerCard(
            seconds: _seconds,
            onChanged: (int value) => setState(() => _seconds = value),
          ),
          const SizedBox(height: 28),
          Text('倒计时名称', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _InputCard(
            controller: _controller,
            hint: '例如：煮鸡蛋',
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final String name =
        _controller.text.trim().isEmpty ? '倒计时' : _controller.text.trim();
    await widget.onSave(name, _seconds);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class AddLabelPage extends StatefulWidget {
  const AddLabelPage({
    super.key,
    required this.onSave,
  });

  final Future<void> Function(String label) onSave;

  @override
  State<AddLabelPage> createState() => _AddLabelPageState();
}

class EditLabelPage extends StatefulWidget {
  const EditLabelPage({
    super.key,
    required this.initialLabel,
    required this.onSave,
    required this.onDelete,
  });

  final String initialLabel;
  final Future<void> Function(String label) onSave;
  final Future<void> Function() onDelete;

  @override
  State<EditLabelPage> createState() => _EditLabelPageState();
}

class _EditLabelPageState extends State<EditLabelPage> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _deleting = false;

  String get _label => _controller.text.trim();

  bool get _canSave {
    return !_saving &&
        !_deleting &&
        _label.isNotEmpty &&
        _label != widget.initialLabel;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: '修改标签',
      canSave: _canSave,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('标签名称', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _InputCard(
            controller: _controller,
            hint: '例如：阅读',
          ),
          const SizedBox(height: 26),
          _DeleteLabelButton(
            label: _deleting ? '删除中...' : '删除标签',
            onPressed: _saving || _deleting ? null : _delete,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(_label);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    if (_deleting) {
      return;
    }
    setState(() => _deleting = true);
    await widget.onDelete();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _AddLabelPageState extends State<AddLabelPage> {
  final TextEditingController _controller = TextEditingController();

  bool get _canSave => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: '添加标签',
      canSave: _canSave,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('标签名称', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _InputCard(
            controller: _controller,
            hint: '例如：阅读',
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }
    await widget.onSave(_controller.text.trim());
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.title,
    required this.child,
    required this.canSave,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.timerPalette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  PlainTextButton(
                    label: '取消',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  PlainTextButton(
                    label: '保存',
                    enabled: canSave,
                    onPressed: onSave,
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Expanded(
                child: SingleChildScrollView(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      color: Colors.white.withOpacity(0.74),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 1,
        style: const TextStyle(
          color: AppTheme.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFD7C9D3),
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _DeleteLabelButton extends StatelessWidget {
  const _DeleteLabelButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const Color danger = Color(0xFFE5486D);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_outline_rounded, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger,
          disabledForegroundColor: danger.withOpacity(0.36),
          side: BorderSide(color: danger.withOpacity(0.36), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
