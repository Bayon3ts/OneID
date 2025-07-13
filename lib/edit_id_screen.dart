import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditIDScreen extends StatefulWidget {
  final String idKey;

  const EditIDScreen({Key? key, required this.idKey}) : super(key: key);

  @override
  State<EditIDScreen> createState() => _EditIDScreenState();
}

class _EditIDScreenState extends State<EditIDScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _controller = TextEditingController();
  bool isLoading = true;

  final Map<String, String> idLabels = {
    'nin': 'National ID',
    'voterCard': "Voter's Card",
    'passport': 'Passport',
    'driversLicense': "Driver's License",
  };

  @override
  void initState() {
    super.initState();
    fetchIDValue();
  }

  Future<void> fetchIDValue() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    final value = data?[widget.idKey];
    setState(() {
      _controller.text = value ?? '';
      isLoading = false;
    });
  }

  Future<void> saveID() async {
    if (user == null) return;
    final updatedValue = _controller.text.trim();
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      widget.idKey: updatedValue,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID updated successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = idLabels[widget.idKey] ?? widget.idKey;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit $label'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: saveID,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}







