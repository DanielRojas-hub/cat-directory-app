// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breeds_page_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BreedsPageModel _$BreedsPageModelFromJson(Map<String, dynamic> json) =>
    _BreedsPageModel(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => BreedModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BreedModel>[],
    );

Map<String, dynamic> _$BreedsPageModelToJson(_BreedsPageModel instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'last_page': instance.lastPage,
      'total': instance.total,
      'data': instance.data,
    };
