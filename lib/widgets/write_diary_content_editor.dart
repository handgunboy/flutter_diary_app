import 'package:flutter/material.dart';

class WriteDiaryContentEditor extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  const WriteDiaryContentEditor({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: fieldKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: '记录今天的故事...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请填写日记内容';
            }
            return null;
          },
          onTap: onTap,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
