import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/duration_picker_card.dart';

class CreateTimerPage extends StatefulWidget {
  const CreateTimerPage(
      {super.key, required this.palette, required this.initialSeconds});

  final AppPalette palette;
  final int initialSeconds;

  @override
  State<CreateTimerPage> createState() => _CreateTimerPageState();
}

class _CreateTimerPageState extends State<CreateTimerPage> {
  late int _hours;
  late int _minutes;
  late int _seconds;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hours = widget.initialSeconds ~/ 3600;
    _minutes = (widget.initialSeconds % 3600) ~/ 60;
    _seconds = widget.initialSeconds % 60;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _totalSeconds => _hours * 3600 + _minutes * 60 + _seconds;

  void _save() {
    if (_totalSeconds <= 0) return;
    Navigator.of(context).pop(
      SavedTimer(
        name: _nameController.text.trim().isEmpty
            ? '自定义倒计时'
            : _nameController.text.trim(),
        seconds: _totalSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CapsuleButton(
                      label: '取消',
                      onPressed: () => Navigator.of(context).pop()),
                  const Spacer(),
                  const Text('创建倒计时', style: AppText.navTitle),
                  const Spacer(),
                  CapsuleButton(
                      label: '保存',
                      onPressed: _totalSeconds > 0 ? _save : null,
                      disabled: _totalSeconds <= 0),
                ],
              ),
              const SizedBox(height: 86),
              const Text('选择倒计时时长', style: AppText.section),
              const SizedBox(height: 28),
              WheelPickerPanel(
                palette: widget.palette,
                hours: _hours,
                minutes: _minutes,
                seconds: _seconds,
                onHoursChanged: (value) => setState(() => _hours = value),
                onMinutesChanged: (value) => setState(() => _minutes = value),
                onSecondsChanged: (value) => setState(() => _seconds = value),
              ),
              const SizedBox(height: 52),
              const Text('倒计时名称', style: AppText.section),
              const SizedBox(height: 22),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                style: AppText.input,
                decoration: InputDecoration(
                  hintText: '例如：煮鸡蛋',
                  hintStyle: AppText.inputHint,
                  filled: true,
                  fillColor: AppColors.pinkBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide:
                        BorderSide(color: widget.palette.softBorder, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide:
                        BorderSide(color: widget.palette.color, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
