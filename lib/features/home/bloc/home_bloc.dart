import 'package:flutter_bloc/flutter_bloc.dart';

import './home_event.dart';
import './home_state.dart';

// abstract class HomeEvent {}
//
// class LoadHomeEvent extends HomeEvent {
//   final String mainCategorySlug;
//   LoadHomeEvent({required this.mainCategorySlug});
// }

// abstract class HomeState {}
//
// class HomeInitial extends HomeState {}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial());
}
