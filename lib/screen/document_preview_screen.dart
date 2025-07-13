import 'package:flutter/material.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DocumentPreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Document Preview")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.network(data['frontImageUrl'], height: 200),
            const SizedBox(height: 10),
            Image.network(data['backImageUrl'], height: 200),
            const SizedBox(height: 20),
            _infoTile("Full Name", data['fullName']),
            _infoTile("Date of Birth", data['dob']),
            _infoTile("Document Number", data['documentNumber']),
            _infoTile("Expiry Date", data['expiryDate']),
            _infoTile("Issuing Authority", data['issuingAuthority']),
            _infoTile("Status", data['status']),
            _infoTile("Date Added", data['dateAdded'].toDate().toString()),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    );
  }
}
