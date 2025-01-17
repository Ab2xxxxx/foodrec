import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../models/chart_data.dart';
import '../models/macro_data.dart';

class MealService {
  final CollectionReference entryCollection;

  MealService()
      : entryCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('meals');

  Future<void> addMeal(Meal meal) async {
    try {
      final existingMeal = await entryCollection
          .where('date', isEqualTo: meal.date)
          .limit(1)
          .get();

      if (existingMeal.docs.isEmpty) {
        await entryCollection.add(meal.toMap());
      } else {
        print('Meal already exists for the given date');
      }
    } catch (e) {
      debugPrint('Error saving meal: $e');
      rethrow;
    }
  }


  Future<void> removeEntry(
      String mealDate, String entryId, String label) async {
    try {
      final snapshot =
          await entryCollection.where('date', isEqualTo: mealDate).get();
      final mealDocument = snapshot.docs.first;

      final meal = Meal.fromJson(mealDocument.data() as Map<String, dynamic>);
      var entryToRemove;
      switch (label) {
        case 'Breakfast':
          for (var entry in meal.breakfast!) {
            if (entry.id == entryId) {
              entryToRemove = (entry);
            }
          }
          meal.breakfast?.remove(entryToRemove);
          break; 
        case 'Lunch':
          for (var entry in meal.lunch!) {
            if (entry.id == entryId) {
              entryToRemove = (entry);
            }
          }
          meal.lunch?.remove(entryToRemove);
          break;
        case 'Dinner':
          for (var entry in meal.dinner!) {
            if (entry.id == entryId) {
              entryToRemove = (entry);
            }
          }
          meal.dinner?.remove(entryToRemove);
          break;
        case 'Snack':
          for (var entry in meal.snack!) {
            if (entry.id == entryId) {
              entryToRemove = (entry);
            }
          }
          meal.snack?.remove(entryToRemove);
          break;
      }

      meal.dailyCalorie -= entryToRemove.calories;
      meal.macroData.carbs -= entryToRemove.carbs;
      meal.macroData.fat -= entryToRemove.fat;
      meal.macroData.protein -= entryToRemove.protein;

      await mealDocument.reference.delete(); 
      await entryCollection
          .add(meal.toMap()); 
    } catch (e) {
      debugPrint('Error removing entry: $e');
      rethrow;
    }
  }


  Future<void> updateMeal(Meal meal) async {
    try {
      final snapshot =
          await entryCollection.where('date', isEqualTo: meal.date).get();
      final mealDocument = snapshot.docs.first;
      await mealDocument.reference.update(meal.toMap());
    } catch (e) {
      debugPrint('Error updating meal: $e');
      rethrow;
    }
  }

  Future<Meal?> getMeal(String date) async {
    final snapshot = await entryCollection.where('date', isEqualTo: date).get();

    if (snapshot.docs.isNotEmpty) {
      Map<String, dynamic>? data =
          snapshot.docs.first.data() as Map<String, dynamic>?;
      // print(data);
      if (data != null) {
        return Meal.fromJson(data);
      }
    }
    return null;
  }

  Future<double> getDailyCalorie(DateTime selectedDate) async {
    final snapshot = await entryCollection
        .where('date',
            isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate.toLocal()))
        .get();

    if (snapshot.docs.isNotEmpty) {
      Map<String, dynamic>? data =
          snapshot.docs.first.data() as Map<String, dynamic>?;
      if (data != null) {
        return Meal.fromJson(data).dailyCalorie;
      }
    }
    return 0;
  }

  Future<MacroData> getDailyMacro(DateTime selectedDate) async {
    final snapshot = await entryCollection
        .where('date',
            isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate.toLocal()))
        .get();

    if (snapshot.docs.isNotEmpty) {
      Map<String, dynamic>? data =
          snapshot.docs.first.data() as Map<String, dynamic>?;

      if (data != null) {
        if (data.containsKey('macroData')) {
          final info = data['macroData'];
          return MacroData(
            carbs: info['carbs'],
            fat: info['fat'],
            protein: info['protein'],
          );
        } else {
          debugPrint('Error: The entry does not contain macroData.');
        }
      }
    }
    return MacroData();
  }

  Future<List<ChartData>> getWeeklyCalorie(DateTime selectedDate) async {
    List<ChartData> calorieList = <ChartData>[
      ChartData('Mon', 0),
      ChartData('Tue', 0),
      ChartData('Wed', 0),
      ChartData('Thu', 0),
      ChartData('Fri', 0),
      ChartData('Sat', 0),
      ChartData('Sun', 0),
    ];

    DateTime monday =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    for (var i = 0; i < 7; i++) {
      DateTime weekday = monday.add(Duration(days: i)).toLocal();
      final snapshot = await entryCollection
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(weekday))
          .get();

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic>? data =
            snapshot.docs.first.data() as Map<String, dynamic>?;
        if (data != null) {
          calorieList[i] = ChartData(DateFormat('EE').format(weekday),
              Meal.fromJson(data).dailyCalorie.toInt().toDouble());
        }
      }
    }
    return calorieList;
  }
}
