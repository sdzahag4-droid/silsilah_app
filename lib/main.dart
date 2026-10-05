import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const String scriptUrl = 'https://script.google.com/macros/s/AKfycbzIpRWoRWPkzXGfXrH36BmQaYgGBGvG_2iDBACniiC4hRwBwCG3oUYjVluyg1GWX1do/exec';

void main() {
  runApp(const SilsilahApp());
}

class SilsilahApp extends StatelessWidget {
  const SilsilahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Silsilah Keluarga',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    // Hardcoded simple auth based on sheets setup
    if (_userController.text == 'admin' && _passController.text == '123456') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProjectScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau Password salah!')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Silsilah Keluarga')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

// --- PROJECT SCREEN ---
class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  _ProjectScreenState createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  List projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getProjects'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          projects = data.sublist(1); // skip header
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _addProjectDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Project Silsilah Baru'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Keluarga / Project')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              String id = DateTime.now().millisecondsSinceEpoch.toString();
              Navigator.pop(context);
              setState(() => isLoading = true);
              await http.post(
                Uri.parse(scriptUrl),
                body: json.encode({'action': 'addProject', 'project_id': id, 'project_name': nameController.text}),
              );
              fetchProjects();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Project Silsilah')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(projects[index][1]),
                  subtitle: Text('ID: ${projects[index][0]}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeViewScreen(projectId: projects[index][0], projectName: projects[index][1]),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- TREE VIEW & MEMBER SCREEN ---
class TreeViewScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  const TreeViewScreen({super.key, required this.projectId, required this.projectName});

  @override
  _TreeViewScreenState createState() => _TreeViewScreenState();
}

class _TreeViewScreenState extends State<TreeViewScreen> {
  List members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getMembers&project_id=${widget.projectId}'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          members = data.sublist(1); // skip header
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _addMemberDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController relationController = TextEditingController();
    TextEditingController parentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Anggota Keluarga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Hubungan (Contoh: Anak, Ayah, Ibu)')),
            TextField(controller: parentController, decoration: const InputDecoration(labelText: 'ID Orang Tua (Opsional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              String id = DateTime.now().millisecondsSinceEpoch.toString();
              Navigator.pop(context);
              setState(() => isLoading = true);
              await http.post(
                Uri.parse(scriptUrl),
                body: json.encode({
                  'action': 'addMember',
                  'id': id,
                  'project_id': widget.projectId,
                  'name': nameController.text,
                  'relation': relationController.text,
                  'parent_id': parentController.text.isEmpty ? '-' : parentController.text
                }),
              );
              fetchMembers();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Silsilah Keluarga: ${widget.projectName}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              ...members.map((m) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8.0),
                child: pw.Text('• ${m[2]} (${m[3]}) -> Orang Tua ID: ${m[4]}'),
              )),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onPdfAction: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPdf),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? const Center(child: Text('Belum ada data anggota keluarga.'))
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.account_tree, color: Colors.blue),
                        title: Text(members[index][2], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Hubungan: ${members[index][3]} | Parent ID: ${members[index][4]}'),
                        trailing: Text('ID: ${members[index][0]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemberDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}