import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NoteScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final notesRef = FirebaseFirestore.instance.collection('notes');

  void showNoteDialog(BuildContext context, {DocumentSnapshot? doc}) {
    if (doc != null) {
      titleController.text = doc['title'];
      contentController.text = doc['content'];
    } else {
      titleController.clear();
      contentController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc != null ? 'Edit Note' : 'New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: contentController, decoration: InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                final data = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'timestamp': DateTime.now(),
                  'userId': FirebaseAuth.instance.currentUser!.uid,
                };

                if (doc == null)
                  notesRef.add(data);
                else
                  notesRef.doc(doc.id).update(data);

                Navigator.pop(context);
              },
              child: Text(doc != null ? 'Update' : 'Add'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
        actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: Icon(Icons.logout))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNoteDialog(context),
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notesRef.where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final ts = (doc['timestamp'] as Timestamp).toDate();

              return ListTile(
                title: Text(doc['title']),
                subtitle: Text("Last edited: $ts"),
                onTap: () => showNoteDialog(context, doc: doc),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => notesRef.doc(doc.id).delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
