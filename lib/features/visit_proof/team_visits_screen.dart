import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/visit_proof_model.dart';
import '../../data/services/visit_proof_service.dart';

class TeamVisitsScreen extends StatefulWidget {
  const TeamVisitsScreen({Key? key}) : super(key: key);

  @override
  State<TeamVisitsScreen> createState() => _TeamVisitsScreenState();
}

class _TeamVisitsScreenState extends State<TeamVisitsScreen> {
  late Future<List<VisitProof>> _teamProofsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _teamProofsFuture = VisitProofService.instance.getTeamProofs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Visits"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<VisitProof>>(
        future: _teamProofsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No visits recorded by your team."));
          }

          final proofs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: proofs.length,
            itemBuilder: (context, index) {
              final proof = proofs[index];
              return _VisitCard(proof: proof);
            },
          );
        },
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final VisitProof proof;
  const _VisitCard({Key? key, required this.proof}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = VisitProofService.instance.getFullImageUrl(proof.proofImageUrl);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(proof.capturedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Employee Name & Time
          ListTile(
            leading: CircleAvatar(
              child: Text(proof.employeeName?[0] ?? '?'),
            ),
            title: Text(proof.employeeName ?? 'Unknown Employee',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(dateStr),
          ),

          // Image
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, obj, trace) => const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),

          // Details: Client & Comment
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        proof.clientName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (proof.comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    proof.comment,
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}