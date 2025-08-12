
import 'package:voice/data/notifiers.dart';
import 'package:flutter/material.dart';

class EditPage extends StatelessWidget {
  const EditPage ({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, List<double>>>(
      valueListenable: voicesNotifier,
      builder: (context, faces, _) {
        if (faces.isEmpty) {
          return const Center(
            child: Text('暂无已保存的声纹'),
          );
        }
        return ListView(
          children: faces.entries.map((entry) {
            final name = entry.key;
            final vector = entry.value;
            return ListTile(
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _editName(context, name, vector);
                },
              ),
              onLongPress: () {
                _deleteFace(context, name);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _editName(BuildContext context, String oldName, List<double> vector) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final updated = Map<String, List<double>>.from(voicesNotifier.value);
                updated.remove(oldName);
                updated[newName] = vector;
                voicesNotifier.value = updated;
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteFace(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除人脸'),
        content: Text('确定删除 "$name" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final updated = Map<String, List<double>>.from(voicesNotifier.value);
              updated.remove(name);
              voicesNotifier.value = updated;
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}