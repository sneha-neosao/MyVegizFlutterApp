import '../../data/models/homePage_model.dart';

abstract class HomePageState {}

class HomePageInitial extends HomePageState {}

class HomePageLoading extends HomePageState {}

class HomePageLoaded extends HomePageState {
  final HomePageModel homePageModel;
  HomePageLoaded(this.homePageModel);
}

class HomePageError extends HomePageState {
  final String message;
  HomePageError(this.message);
}
