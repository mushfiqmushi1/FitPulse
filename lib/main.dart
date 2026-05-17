import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FitPulseApp());
}

class FitPulseApp extends StatelessWidget {
  const FitPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 100,
                width: 100,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 80, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(_isLogin ? 'Welcome Back' : 'Create Account', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _submit, child: Text(_isLogin ? 'Login' : 'Sign Up'))),
              TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Need an account? Sign Up' : 'Already have an account? Login')),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  void _showAddDataModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const AddDataForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FitPulse Dashboard'), elevation: 0),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 50,
                    width: 50,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.tealAccent),
                  ),
                  const SizedBox(height: 10),
                  const Text('FitPulse Menu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.directions_run), title: const Text('Activity History'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(title: 'Activities', collectionName: 'activities')))),
            ListTile(leading: const Icon(Icons.monitor_weight), title: const Text('Weight History'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(title: 'Weight', collectionName: 'weights')))),
            ListTile(leading: const Icon(Icons.favorite), title: const Text('Blood Pressure History'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(title: 'Blood Pressure', collectionName: 'bps')))),
            ListTile(leading: const Icon(Icons.height), title: const Text('Height History'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(title: 'Height', collectionName: 'heights')))),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent)), onTap: () => FirebaseAuth.instance.signOut()),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weight Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              flex: 1,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 16.0, bottom: 16.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('weights').orderBy('date').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No data yet'));
                      
                      List<FlSpot> spots = [];
                      List<String> dateLabels = []; 
                      double minX = 0, maxX = 0, minY = double.infinity, maxY = 0;
                      
                      for (int i = 0; i < snapshot.data!.docs.length; i++) {
                        var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
                        double weight = (data['weight'] ?? 0).toDouble();
                        spots.add(FlSpot(i.toDouble(), weight));
                        
                        Timestamp? ts = data['date'] as Timestamp?;
                        if (ts != null) {
                          dateLabels.add(DateFormat('dd MMM').format(ts.toDate()));
                        } else {
                          dateLabels.add('');
                        }

                        if (weight < minY) minY = weight;
                        if (weight > maxY) maxY = weight;
                        maxX = i.toDouble();
                      }
                      if (minY == double.infinity) minY = 0;
                      
                      return LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < dateLabels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(dateLabels[index], style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: minX, maxX: maxX, minY: minY - 2, maxY: maxY + 2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots, 
                              isCurved: true, 
                              color: Theme.of(context).colorScheme.primary, 
                              barWidth: 3, 
                              isStrokeCapRound: true, 
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recent Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('activities').orderBy('date', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No activities yet'));
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      IconData icon = Icons.directions_run;
                      if (data['type'] == 'Walk') icon = Icons.directions_walk;
                      if (data['type'] == 'Cycle') icon = Icons.directions_bike;
                      
                      Timestamp? ts = data['date'] as Timestamp?;
                      String dateStr = ts != null ? DateFormat('dd MMM, yyyy').format(ts.toDate()) : 'Recent';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(icon)),
                          title: Text(data['type'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${data['distance']} km in ${data['duration']} mins'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDataModal, child: const Icon(Icons.add)),
    );
  }
}

class AddDataForm extends StatefulWidget {
  const AddDataForm({super.key});

  @override
  State<AddDataForm> createState() => _AddDataFormState();
}

class _AddDataFormState extends State<AddDataForm> {
  String _selectedTab = 'Activity';
  String _activityType = 'Run';
  final _val1Controller = TextEditingController();
  final _val2Controller = TextEditingController();

  Future<void> _saveData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = <String, dynamic>{'date': Timestamp.now()};
    String collection = '';

    if (_selectedTab == 'Activity') {
      collection = 'activities';
      data['type'] = _activityType;
      data['distance'] = double.tryParse(_val1Controller.text) ?? 0;
      data['duration'] = int.tryParse(_val2Controller.text) ?? 0;
    } else if (_selectedTab == 'Weight') {
      collection = 'weights';
      data['weight'] = double.tryParse(_val1Controller.text) ?? 0;
    } else if (_selectedTab == 'BP') {
      collection = 'bps';
      data['systolic'] = int.tryParse(_val1Controller.text) ?? 0;
      data['diastolic'] = int.tryParse(_val2Controller.text) ?? 0;
    } else if (_selectedTab == 'Height') {
      collection = 'heights';
      data['height'] = double.tryParse(_val1Controller.text) ?? 0;
    }

    Navigator.pop(context);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection(collection).add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Activity', 'Weight', 'BP', 'Height'].map((tab) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: _selectedTab == tab,
                    onSelected: (v) {
                      setState(() {
                        _selectedTab = tab;
                        _val1Controller.clear();
                        _val2Controller.clear();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedTab == 'Activity') ...[
            DropdownButtonFormField<String>(
              initialValue: _activityType,
              items: ['Run', 'Walk', 'Cycle'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _activityType = v!),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _val1Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Distance (km)')),
            const SizedBox(height: 12),
            TextField(controller: _val2Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Duration (mins)')),
          ] else if (_selectedTab == 'Weight') ...[
            TextField(controller: _val1Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Weight (kg)')),
          ] else if (_selectedTab == 'BP') ...[
            Row(
              children: [
                Expanded(child: TextField(controller: _val1Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Systolic (e.g. 120)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _val2Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Diastolic (e.g. 80)'))),
              ],
            ),
          ] else if (_selectedTab == 'Height') ...[
            TextField(controller: _val1Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Height (cm)')),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveData, child: const Text('Save Record'))),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final String title;
  final String collectionName;
  const HistoryScreen({super.key, required this.title, required this.collectionName});

  Future<void> _generateAndPrintPDF(BuildContext context, List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$title Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  if (collectionName == 'activities') ['Date', 'Type', 'Distance (km)', 'Time (min)']
                  else if (collectionName == 'weights') ['Date', 'Weight (kg)']
                  else if (collectionName == 'bps') ['Date', 'Systolic', 'Diastolic']
                  else ['Date', 'Height (cm)'],
                  
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    Timestamp? ts = data['date'] as Timestamp?;
                    String dateStr = ts != null ? DateFormat('yyyy-MM-dd').format(ts.toDate()) : 'N/A';
                    
                    if (collectionName == 'activities') return [dateStr, data['type'].toString(), data['distance'].toString(), data['duration'].toString()];
                    if (collectionName == 'weights') return [dateStr, data['weight'].toString()];
                    if (collectionName == 'bps') return [dateStr, data['systolic'].toString(), data['diastolic'].toString()];
                    return [dateStr, data['height'].toString()];
                  })
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title}_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection(collectionName).orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No data found.'));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndPrintPDF(context, snapshot.data!.docs),
                    icon: const Icon(Icons.print),
                    label: const Text('Print / Save as PDF'),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    Timestamp? ts = data['date'] as Timestamp?;
                    String dateStr = ts != null ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate()) : 'Unknown Date';
                    
                    String subtitle = '';
                    if (collectionName == 'activities') subtitle = '${data['type']} - ${data['distance']} km, ${data['duration']} mins';
                    if (collectionName == 'weights') subtitle = '${data['weight']} kg';
                    if (collectionName == 'bps') subtitle = '${data['systolic']} / ${data['diastolic']}';
                    if (collectionName == 'heights') subtitle = '${data['height']} cm';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month, color: Colors.tealAccent),
                        title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(subtitle, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('users').doc(uid).collection(collectionName).doc(doc.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted')));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}