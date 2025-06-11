import 'package:flutter/material.dart';

import '../models/data.dart';
import '../services/database_services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  final DatabaseServices _databaseServices = DatabaseServices.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        backgroundColor: Color(0xffF7F8F8),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _dataList(),
    );
  }

  Widget _dataList() {
    return FutureBuilder(
      future: _databaseServices.getAllData(), 
      builder: (context, snapshot) {
        return ListView.builder(
          itemCount: snapshot.data?.length ?? 0,
          itemBuilder: (context, index) {
            Data data = snapshot.data![index];
            return ListTile(
              title: Text(data.timestamp),
              subtitle: Text('HR: ${data.heartRate} BPM, SpO2: ${data.spo2}%, Temp: ${data.temperature}°C'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  // Show confirmation dialog
                  bool? shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Delete Record'),
                        content: Text('Are you sure you want to delete this record?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDelete == true) {
                    try {
                      _databaseServices.deleteData(data.id);
                      setState(() {}); // Refresh the list
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Record deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting record: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            );
        },
        );
      },
    ); 
  }
}