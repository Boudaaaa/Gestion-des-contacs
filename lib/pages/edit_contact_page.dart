import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import '../db/database_helper.dart';

class EditContactPage extends StatefulWidget {
  final Contact? contact;

  const EditContactPage({Key? key, this.contact}) : super(key: key);

  @override
  State<EditContactPage> createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    if (widget.contact == null) {
      // create
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final id = DateTime.now().millisecondsSinceEpoch;
        final created = Contact(id: id, name: name, phone: phone);
        final existing = prefs.getString('contacts_json');
        List list = existing != null ? json.decode(existing) as List : [];
        list.add(created.toMap());
        await prefs.setString('contacts_json', json.encode(list));
      } else {
        await DatabaseHelper.instance.create(Contact(name: name, phone: phone));
      }
    } else {
      // update
      final contact = widget.contact!;
      contact.name = name;
      contact.phone = phone;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final existing = prefs.getString('contacts_json');
        if (existing != null) {
          final List list = json.decode(existing) as List;
          final idx = list.indexWhere((e) => (e['id'] as int) == contact.id);
          if (idx != -1) {
            list[idx] = contact.toMap();
            await prefs.setString('contacts_json', json.encode(list));
          }
        }
      } else {
        await DatabaseHelper.instance.update(contact);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.contact == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Ajouter un contact' : 'Modifier le contact')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
