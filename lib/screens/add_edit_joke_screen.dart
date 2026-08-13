import 'package:flutter/material.dart';
import '../models/joke.dart';
import '../database/database_helper.dart';

class AddEditJokeScreen extends StatefulWidget {
  final Joke? joke;
  const AddEditJokeScreen({super.key, this.joke});

  @override
  State<AddEditJokeScreen> createState() => _AddEditJokeScreenState();
}

class _AddEditJokeScreenState extends State<AddEditJokeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _setupCtrl;
  late final TextEditingController _punchlineCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _notesCtrl;
  String _type = 'observation';
  String _status = 'raw';

  final Map<String, String> typeLabels = {
    'observation': 'Наблюдение',
    'story': 'История',
    'oneline': 'Одностишье',
    'crowd': 'Взаимодействие',
    'sketch': 'Скетч',
  };

  final Map<String, String> statusLabels = {
    'raw': 'Сырая идея',
    'wip': 'На проработке',
    'ready': 'Рабочая',
    'stage': 'В сете',
    'dead': 'Списана',
  };

  @override
  void initState() {
    super.initState();
    final j = widget.joke;
    _titleCtrl = TextEditingController(text: j?.title ?? '');
    _setupCtrl = TextEditingController(text: j?.setup ?? '');
    _punchlineCtrl = TextEditingController(text: j?.punchline ?? '');
    _tagsCtrl = TextEditingController(text: j?.tags ?? '');
    _timeCtrl = TextEditingController(text: j?.time ?? '1:00');
    _notesCtrl = TextEditingController(text: j?.notes ?? '');
    if (j != null) {
      _type = j.type;
      _status = j.status;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _setupCtrl.dispose();
    _punchlineCtrl.dispose();
    _tagsCtrl.dispose();
    _timeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final joke = Joke(
      id: widget.joke?.id,
      title: _titleCtrl.text.trim(),
      setup: _setupCtrl.text.trim(),
      punchline: _punchlineCtrl.text.trim(),
      type: _type,
      status: _status,
      tags: _tagsCtrl.text.trim(),
      time: _timeCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      inSetlist: widget.joke?.inSetlist ?? 0,
      setlistOrder: widget.joke?.setlistOrder ?? 0,
    );
    if (widget.joke == null) {
      await DatabaseHelper.instance.insertJoke(joke);
    } else {
      await DatabaseHelper.instance.updateJoke(joke);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.joke == null ? 'Новая шутка' : 'Редактировать'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('СОХРАНИТЬ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Заголовок', hintText: 'Короткая метка'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: typeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Статус'),
                      items: statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _setupCtrl,
                decoration: const InputDecoration(labelText: 'Сетап (завязка)', hintText: 'Что происходит до панчлайна...'),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _punchlineCtrl,
                decoration: const InputDecoration(labelText: 'Панчлайн (развязка)', hintText: 'Сама шутка...'),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _tagsCtrl,
                      decoration: const InputDecoration(labelText: 'Теги', hintText: 'семья, работа, метро'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeCtrl,
                      decoration: const InputDecoration(labelText: 'Время', hintText: '1:30'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Заметки со сцены', hintText: 'Что сработало, где провисло...'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
