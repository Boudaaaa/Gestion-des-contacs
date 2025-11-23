import 'package:flutter/material.dart';

import 'models/contact.dart';
import 'db/database_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'pages/edit_contact_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class ContactsApp extends StatelessWidget {
  const ContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure auth is initialized before router reads its state
    // (we don't await here; auth.init() will set notifier and GoRouter listens to it)
    AuthService.instance.init();

    final router = GoRouter(
      refreshListenable: AuthService.instance.notifier,
      redirect: (context, state) {
        final loggedIn = AuthService.instance.isLoggedIn;
        final loggingIn = state.location == '/login';
        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const ContactsHomePage(),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) {
            final contact = state.extra as Contact?;
            return EditContactPage(contact: contact);
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      title: 'Gestion des contacts',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

// Keep a `MyApp` class so tests that import `MyApp` can instantiate it.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContactsApp();
  }
}

class ContactsHomePage extends StatefulWidget {
  const ContactsHomePage({super.key});

  @override
  State<ContactsHomePage> createState() => _ContactsHomePageState();
}

class _ContactsHomePageState extends State<ContactsHomePage> {
  final List<Contact> _contacts = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('contacts_json');
      if (jsonString != null) {
        final List decoded = json.decode(jsonString) as List;
        setState(() {
          _contacts.clear();
          _contacts.addAll(decoded.map((e) => Contact.fromMap(e as Map<String, dynamic>)));
        });
      }
    } else {
      final list = await DatabaseHelper.instance.readAllContacts();
      setState(() {
        _contacts.clear();
        _contacts.addAll(list);
      });
    }
  }

  Future<void> _openContactEditor({Contact? contact}) async {
    // use go_router to push the edit page; await result and reload
    final result = await GoRouter.of(context).push<bool?>('/edit', extra: contact);
    if (result == true) {
      await _loadContacts();
    }
  }

  void _deleteContact(Contact contact) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contact'),
        content: Text('Supprimer "${contact.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (kIsWeb) {
                if (contact.id != null) {
                  final prefs = await SharedPreferences.getInstance();
                  final existing = prefs.getString('contacts_json');
                  if (existing != null) {
                    final List list = json.decode(existing) as List;
                    list.removeWhere((e) => (e['id'] as int) == contact.id);
                    await prefs.setString('contacts_json', json.encode(list));
                  }
                }
              } else {
                if (contact.id != null) {
                  await DatabaseHelper.instance.delete(contact.id!);
                }
              }
              setState(() {
                _contacts.removeWhere((c) => c.id == contact.id);
              });
              if (!mounted) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _searchQuery.isEmpty
        ? _contacts
        : _contacts.where((c) {
            final q = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(q) || c.phone.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des contacts'),
        actions: [
          IconButton(
            tooltip: 'À propos',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('À propos'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gestion des contacts'),
                      const SizedBox(height: 16),
                      const Text('Lien du compte GitHub:'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse('https://github.com/Boudaaaa/Gestion-des-contacs');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text(
                          'https://github.com/Boudaaaa/Gestion-des-contacs',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.logout();
              if (!mounted) return;
              GoRouter.of(context).go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher nom ou numéro',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text('Aucun contact. Appuyez sur + pour en ajouter.', style: Theme.of(context).textTheme.titleMedium),
                  )
                : RefreshIndicator(
                    onRefresh: _loadContacts,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final c = visible[index];
                        final initials = c.name.trim().isNotEmpty
                            ? c.name.trim().split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join()
                            : '?';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(initials)),
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(c.phone),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openContactEditor(contact: c)),
                                IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteContact(c)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openContactEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
