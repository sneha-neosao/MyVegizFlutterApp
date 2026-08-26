import 'package:equatable/equatable.dart';

abstract class CmsPageEvent extends Equatable {
  const CmsPageEvent();

  @override
  List<Object?> get props => [];
}

class FetchCmsPageEvent extends CmsPageEvent {
  final String pageKey;

  const FetchCmsPageEvent(this.pageKey);

  @override
  List<Object?> get props => [pageKey];
}
