import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import 'document_preview_screen.dart';

class AddIDScreen extends StatefulWidget {
  final String userId;

  const AddIDScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddIDScreen> createState() => _AddIDScreenState();
}

class _AddIDScreenState extends State<AddIDScreen>
    with SingleTickerProviderStateMixin {
  File? _frontImage;
  File? _backImage;
  String? _ocrPreviewText;
  bool _isLoading = false;
  bool _showOCRPreview = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _firstNameController = TextEditingController();
  final _surNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _issuingAuthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickImage(bool isFront, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    final recognizedText = await _performOCR(imageFile);

    setState(() {
      _ocrPreviewText = recognizedText;
      _showOCRPreview = true;
      if (isFront) {
        _frontImage = imageFile;
      } else {
        _backImage = imageFile;
      }
    });
    _animationController.forward(from: 0);
  }

  Future<String?> _performOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  String _extractMatch(String text, List<String> patterns, String valuePattern) {
    for (final label in patterns) {
      final regex = RegExp('$label[:\\s]*$valuePattern', caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) return match.group(1)?.trim() ?? '';
    }
    return '';
  }

  void _applyOCR() {
    if (_ocrPreviewText == null) return;
    final text = _ocrPreviewText!;

    // Simulated AI-enhanced regex parsing
    setState(() {
      _firstNameController.text =
          _extractMatch(text, ['name'], r'([A-Z][A-Z\s]+)');
      _dobController.text = _extractMatch(
          text, ['dob', 'date of birth'], r'([\d]{1,2}[-/\.\s][\d]{1,2}[-/\.\s][\d]{2,4})');
      _docNumberController.text = _extractMatch(
          text, ['document number', 'doc no', 'id no', 'number'], r'([\w\d-]+)');
      _expiryDateController.text = _extractMatch(
          text, ['expiry date', 'exp date', 'expiry'], r'([\d]{1,2}[-/\.\s][\d]{1,2}[-/\.\s][\d]{2,4})');
      _issuingAuthController.text =
          _extractMatch(text, ['issued by', 'authority'], r'([A-Za-z\s]+)');
      _showOCRPreview = false;
    });
  }

  Future<String?> _uploadImage(File imageFile, String filename) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('ids')
        .child(widget.userId)
        .child(filename);
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() &&
        _frontImage != null &&
        _backImage != null) {
      setState(() => _isLoading = true);
      try {
        final frontUrl =
        await _uploadImage(_frontImage!, 'front_${const Uuid().v4()}.jpg');
        final backUrl =
        await _uploadImage(_backImage!, 'back_${const Uuid().v4()}.jpg');

        final docId = const Uuid().v4();
        final userRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);
        final userDoc = await userRef.get();
        if (!userDoc.exists) {
          await userRef.set({'createdAt': Timestamp.now()});
        }

        final idData = {
          'id': docId,
          'firstName': _firstNameController.text.trim(),
          'dob': _dobController.text.trim(),
          'documentNumber': _docNumberController.text.trim(),
          'expiryDate': _expiryDateController.text.trim(),
          'issuingAuthority': _issuingAuthController.text.trim(),
          'frontImageUrl': frontUrl,
          'backImageUrl': backUrl,
          'dateAdded': Timestamp.now(),
          'status': 'pending',
        };

        await userRef.collection('ids').doc(docId).set(idData);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentPreviewScreen(data: idData),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving ID: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields and upload both images")),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _frontImage = null;
      _backImage = null;
      _ocrPreviewText = null;
      _showOCRPreview = false;
      _firstNameController.clear();
      _dobController.clear();
      _docNumberController.clear();
      _expiryDateController.clear();
      _issuingAuthController.clear();
    });
  }

  Widget _imagePreview(File? file, bool isFront) {
    return GestureDetector(
      onTap: () => _showImageSourcePicker(isFront),
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          image: file != null
              ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
              : null,
        ),
        child: file == null
            ? Center(child: Text(isFront ? "Add Front Image" : "Add Back Image"))
            : null,
      ),
    );
  }

  void _showImageSourcePicker(bool isFront) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(isFront, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(isFront, ImageSource.gallery);
            },
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (isDate &&
              !RegExp(r'^(\d{1,2}[-/\s]\d{1,2}[-/\s]\d{2,4}|\d{4}-\d{2}-\d{2})$')
                  .hasMatch(value)) {
            return 'Invalid date format';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _dobController.dispose();
    _docNumberController.dispose();
    _expiryDateController.dispose();
    _issuingAuthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New ID")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _showOCRPreview && _ocrPreviewText != null
            ? FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("OCR Preview",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(_ocrPreviewText!,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Use Text for Autofill"),
                onPressed: _applyOCR,
              ),
              TextButton(
                child: const Text("Cancel"),
                onPressed: () =>
                    setState(() => _showOCRPreview = false),
              ),
            ],
          ),
        )
            : Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  _imagePreview(_frontImage, true),
                  const SizedBox(width: 10),
                  _imagePreview(_backImage, false),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(_firstNameController, "Full Name"),
              _buildTextField(_dobController, "Date of Birth",
                  isDate: true),
              _buildTextField(
                  _docNumberController, "Document Number"),
              _buildTextField(_expiryDateController, "Expiry Date",
                  isDate: true),
              _buildTextField(
                  _issuingAuthController, "Issuing Authority"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Save ID"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _clearForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text("Clear Form"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
