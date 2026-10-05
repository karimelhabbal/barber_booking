import 'package:cloud_firestore/cloud_firestore.dart';

int readInt(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

DateTime? readDate(Object? v) => v is Timestamp ? v.toDate() : null;

DateTime readDateOr(Object? v, DateTime fallback) => readDate(v) ?? fallback;
