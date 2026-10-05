import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
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
  bool _obscurePassword = true;

  void _login() async {
    if (_userController.text.trim().isEmpty || _passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getUsers'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List users = data is List && data.length > 1 ? data.sublist(1) : []; 
        
        bool isAuthenticated = false;
        for (var row in users) {
          String userSheet = row[0].toString().trim();
          String passSheet = row[1].toString().trim();
          
          if (userSheet == _userController.text.trim() && passSheet == _passController.text.trim()) {
            isAuthenticated = true;
            break;
          }
        }

        if (isAuthenticated) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProjectScreen()),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username atau Password salah!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal terhubung ke server: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🌳', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Silsilah Keluarga',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan masuk untuk mengelola data keluarga',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
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
          projects = data is List && data.length > 1 ? data.sublist(1) : [];
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
        content: TextField(
          controller: nameController, 
          decoration: const InputDecoration(labelText: 'Nama Keluarga / Project (Contoh: Bani Giram)')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              String id = DateTime.now().millisecondsSinceEpoch.toString();
              Navigator.pop(context);
              setState(() => isLoading = true);
              await http.post(
                Uri.parse(scriptUrl),
                body: json.encode({'action': 'addProject', 'project_id': id, 'project_name': nameController.text.trim()}),
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
      appBar: AppBar(title: const Text('Daftar Project Silsilah', style: TextStyle(color: Colors.white)), backgroundColor: Colors.indigo),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(child: Text('Belum ada project silsilah.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    var project = projects[index];
                    String pId = project[0].toString();
                    String pName = project[1].toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Text('📁', style: TextStyle(fontSize: 18))),
                        title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: $pId'),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TreeViewScreen(projectId: pId, projectName: pName),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProjectDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
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
          members = data is List && data.length > 1 ? data.sublist(1) : [];
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
            TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Hubungan (Contoh: Ayah, Ibu, Anak)')),
            TextField(controller: parentController, decoration: const InputDecoration(labelText: 'ID Orang Tua (Kosongkan jika Leluhur Utama)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              String id = DateTime.now().millisecondsSinceEpoch.toString();
              Navigator.pop(context);
              setState(() => isLoading = true);
              await http.post(
                Uri.parse(scriptUrl),
                body: json.encode({
                  'action': 'addMember',
                  'id': id,
                  'project_id': widget.projectId,
                  'name': nameController.text.trim(),
                  'relation': relationController.text.trim(),
                  'parent_id': parentController.text.isEmpty ? '-' : parentController.text.trim()
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

  // Membangun Tampilan Kotak Silsilah dengan Garis Cabang di UI Flutter
  List<Widget> _buildTreeWidgets() {
    Map<String, List<dynamic>> childrenMap = {};
    List<dynamic> roots = [];

    for (var m in members) {
      String parentId = m.length > 4 ? m[4].toString().trim() : '-';
      if (parentId == '-' || parentId.isEmpty || !members.any((element) => element[0].toString() == parentId)) {
        roots.add(m);
      } else {
        childrenMap.putIfAbsent(parentId, () => []).add(m);
      }
    }

    List<Widget> widgets = [];

    void addRecursive(dynamic member, double indentLevel) {
      String mId = member.isNotEmpty ? member[0].toString() : '';
      String mName = member.length > 2 ? member[2].toString() : '';
      String mRelation = member.length > 3 ? member[3].toString() : '';
      String mParentId = member.length > 4 ? member[4].toString() : '-';

      // Warna kotak berbeda tiap level kedalaman agar mirip bagan silsilah
      Color boxColor = indentLevel == 0 ? Colors.amber[100]! : (indentLevel == 1 ? Colors.blue[50]! : Colors.green[50]!);
      Color borderColor = indentLevel == 0 ? Colors.amber[700]! : (indentLevel == 1 ? Colors.indigo : Colors.green);

      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indentLevel * 28.0, bottom: 8.0, top: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (indentLevel > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 14.0, right: 6.0),
                  child: Container(
                    width: 16,
                    height: 2,
                    color: Colors.indigo,
                  ),
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: boxColor,
                    border: Border.all(color: borderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(mName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                            child: Text('ID: $mId', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Hubungan: $mRelation', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                      if (mParentId != '-' && mParentId.isNotEmpty)
                        Text('Orang Tua ID: $mParentId', style: TextStyle(color: Colors.indigo[800], fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      var children = childrenMap[mId] ?? [];
      for (var child in children) {
        addRecursive(child, indentLevel + 1);
      }
    }

    for (var root in roots) {
      addRecursive(root, 0);
    }

    return widgets;
  }

  // Export PDF dengan Format Kotak Bagan & Keterangan
  void _exportPdf() async {
    final pdf = pw.Document();

    Map<String, List<dynamic>> childrenMap = {};
    List<dynamic> roots = [];

    for (var m in members) {
      String parentId = m.length > 4 ? m[4].toString().trim() : '-';
      if (parentId == '-' || parentId.isEmpty || !members.any((element) => element[0].toString() == parentId)) {
        roots.add(m);
      } else {
        childrenMap.putIfAbsent(parentId, () => []).add(m);
      }
    }

    List<pw.Widget> pdfWidgets = [];

    void addPdfRecursive(dynamic member, double indentLevel) {
      String name = member.length > 2 ? member[2].toString() : '';
      String relation = member.length > 3 ? member[3].toString() : '';
      String id = member.isNotEmpty ? member[0].toString() : '';

      pdfWidgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(left: indentLevel * 20.0, bottom: 6.0),
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('$name ($relation)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('ID: $id', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
        ),
      );

      var children = childrenMap[id] ?? [];
      for (var child in children) {
        addPdfRecursive(child, indentLevel + 1);
      }
    }

    for (var root in roots) {
      addPdfRecursive(root, 0);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Judul Silsilah di PDF
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BAGAN SILSILAH KELUARGA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Project: ${widget.projectName}', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            ...pdfWidgets,
            pw.SizedBox(height: 20),
            // Keterangan di PDF
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('KETERANGAN:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 4),
                  pw.Text('- Bagan disusun secara hierarki dari leluhur utama ke keturunan.', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('- Garis panah/cabang menunjukkan hubungan garis keturunan keluarga.', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? const Center(child: Text('Belum ada data anggota keluarga.'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: _buildTreeWidgets(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemberDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}