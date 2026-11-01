import 'package:flutter/material.dart';

import '../models/event.dart';
import '../utils/format.dart';

// что форма возвращает через Navigator.pop
class EventDraft {
  final String title;
  final String description;
  final DateTime start;
  final DateTime? end;
  final EventCategory category;

  EventDraft({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.category,
  });
}

// Создание (event == null) и редактирование события.
// В конструктор передаём выбранный в календаре день - он будет датой по умолчанию
class EventEditScreen extends StatefulWidget {
  final Event? event;
  final DateTime initialDate;

  const EventEditScreen({super.key, this.event, required this.initialDate});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  late DateTime date;
  late TimeOfDay startTime;
  TimeOfDay? endTime;
  late EventCategory category;
  String? timeError;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    Event? e = widget.event;
    titleController = TextEditingController(text: e?.title ?? '');
    descriptionController = TextEditingController(text: e?.description ?? '');
    category = e?.category ?? EventCategory.work;

    if (e != null) {
      date = dateOnly(e.start);
      startTime = TimeOfDay.fromDateTime(e.start);
      endTime = e.end == null ? null : TimeOfDay.fromDateTime(e.end!);
    } else {
      // новое событие по умолчанию с 9 до 10
      date = dateOnly(widget.initialDate);
      startTime = const TimeOfDay(hour: 9, minute: 0);
      endTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime day, TimeOfDay time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  DateTime get start => _combine(date, startTime);
  DateTime? get end => endTime == null ? null : _combine(date, endTime!);

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => date = dateOnly(picked));
  }

  Future<void> pickStart() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (picked == null) return;
    setState(() {
      startTime = picked;
      timeError = null;
    });
  }

  Future<void> pickEnd() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: endTime ?? startTime,
    );
    if (picked == null) return;
    setState(() {
      endTime = picked;
      timeError = null;
    });
  }

  void save() {
    bool titleOk = _formKey.currentState!.validate();
    // время проверяем отдельно, это не текстовое поле формы
    String? error = checkEventTime(start, end);
    setState(() => timeError = error);
    if (!titleOk || error != null) return;

    Navigator.pop(
      context,
      EventDraft(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        start: start,
        end: end,
        category: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактирование' : 'Новое событие'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Сохранить',
            onPressed: save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: titleController,
              autofocus: !isEditing,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название события';
                }
                return null;
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Дата'),
              trailing: Text(formatDate(date)),
              onTap: pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Начало'),
              trailing: Text(startTime.format(context)),
              onTap: pickStart,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.timelapse),
              title: const Text('Указать окончание'),
              value: endTime != null,
              onChanged: (on) {
                setState(() {
                  timeError = null;
                  // включили - ставим конец на час позже начала
                  endTime = on
                      ? TimeOfDay(
                          hour: (startTime.hour + 1) % 24,
                          minute: startTime.minute,
                        )
                      : null;
                });
              },
            ),
            if (endTime != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const SizedBox(),
                title: const Text('Окончание'),
                trailing: Text(endTime!.format(context)),
                onTap: pickEnd,
              ),
            if (timeError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  timeError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            const Text('Категория'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (EventCategory c in EventCategory.values)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: c.color, radius: 6),
                    label: Text(c.label),
                    selected: category == c,
                    onSelected: (_) => setState(() => category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
