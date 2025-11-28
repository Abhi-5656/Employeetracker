import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/visit_proof_service.dart';

class AddVisitProofScreen extends StatefulWidget {
  const AddVisitProofScreen({Key? key}) : super(key: key);

  @override
  State<AddVisitProofScreen> createState() => _AddVisitProofScreenState();
}

class _AddVisitProofScreenState extends State<AddVisitProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _commentController = TextEditingController();

  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void dispose() {
    _clientController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _captureEvidence() async {
    // 1. Check Location Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // 2. Get Location BEFORE or DURING Camera (to ensure accuracy)
      // We fetch it now so we have it ready when the photo is taken
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Open Camera
      final picker = ImagePicker();
      // force camera only for "Proof"
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _currentPosition = position;
        });
      }
    } catch (e) {
      _showError('Error capturing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null || _currentPosition == null) {
      _showError('Please take a photo first.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await VisitProofService.instance.submitProof(
        imageFile: _imageFile!,
        clientName: _clientController.text.trim(),
        comment: _commentController.text.trim(),
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit proof submitted successfully!')),
        );
        Navigator.pop(context); // Go back to My Day
      }
    } catch (e) {
      _showError('Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Client Visit")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Image Preview Section ---
              GestureDetector(
                onTap: _captureEvidence,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Tap to take photo"),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "📍 Location captured: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),

              // --- Form Fields ---
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Client / Destination Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comments / Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // --- Submit Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)
                )
                    : const Text("SUBMIT PROOF"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}