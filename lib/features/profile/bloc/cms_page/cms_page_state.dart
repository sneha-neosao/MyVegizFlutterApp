import 'package:equatable/equatable.dart';
import '../../data/models/cms_page_model.dart';

abstract class CmsPageState extends Equatable {
  const CmsPageState();

  @override
  List<Object?> get props => [];
}

class CmsPageInitial extends CmsPageState {
  const CmsPageInitial();
}

class CmsPageLoading extends CmsPageState {
  const CmsPageLoading();
}

class CmsPageLoaded extends CmsPageState {
  final CmsPageModel page;

  const CmsPageLoaded(this.page);

  @override
  List<Object?> get props => [page];
}

class CmsPageEmpty extends CmsPageState {
  const CmsPageEmpty();
}

class CmsPageError extends CmsPageState {
  final String message;

  const CmsPageError(this.message);

  @override
  List<Object?> get props => [message];
}
