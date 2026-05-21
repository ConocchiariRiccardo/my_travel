import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';
import 'package:my_travel/data/repositories/viaggio_repository.dart';
import 'package:my_travel/data/repositories/spesa_repository.dart';
import 'package:my_travel/ui/expenses/expense_view_model.dart';
import 'package:my_travel/ui/profile/profile_view_model.dart';

@GenerateMocks([
  AuthViewModel,
  SpesaRepository,
  ViaggioRepository,
  ExpenseViewModel,
  ProfileViewModel,
  User,
])
void main() {}
