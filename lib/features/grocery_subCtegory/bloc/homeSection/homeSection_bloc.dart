import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HomeSectionEvent {}

abstract class HomeSectionState {}

class HomeSectionInitial extends HomeSectionState {}

class HomeSectionsBloc extends Bloc<HomeSectionEvent, HomeSectionState> {
  HomeSectionsBloc() : super(HomeSectionInitial());
}
