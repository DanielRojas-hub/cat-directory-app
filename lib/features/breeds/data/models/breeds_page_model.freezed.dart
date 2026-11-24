// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breeds_page_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BreedsPageModel {

@JsonKey(name: 'current_page') int get currentPage;@JsonKey(name: 'last_page') int get lastPage; int get total; List<BreedModel> get data;
/// Create a copy of BreedsPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedsPageModelCopyWith<BreedsPageModel> get copyWith => _$BreedsPageModelCopyWithImpl<BreedsPageModel>(this as BreedsPageModel, _$identity);

  /// Serializes this BreedsPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BreedsPageModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreedsPageModel&&(identical(other.currentPage, _this.currentPage) || other.currentPage == _this.currentPage)&&(identical(other.lastPage, _this.lastPage) || other.lastPage == _this.lastPage)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.data, _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BreedsPageModel;
  return Object.hash(runtimeType,_this.currentPage,_this.lastPage,_this.total,const DeepCollectionEquality().hash(_this.data));
}

@override
String toString() {
  final _this = this as BreedsPageModel;
  return 'BreedsPageModel(currentPage: ${_this.currentPage}, lastPage: ${_this.lastPage}, total: ${_this.total}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $BreedsPageModelCopyWith<$Res>  {
  factory $BreedsPageModelCopyWith(BreedsPageModel value, $Res Function(BreedsPageModel) _then) = _$BreedsPageModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'current_page') int currentPage,@JsonKey(name: 'last_page') int lastPage, int total, List<BreedModel> data
});




}
/// @nodoc
class _$BreedsPageModelCopyWithImpl<$Res>
    implements $BreedsPageModelCopyWith<$Res> {
  _$BreedsPageModelCopyWithImpl(this._self, this._then);

  final BreedsPageModel _self;
  final $Res Function(BreedsPageModel) _then;

/// Create a copy of BreedsPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? data = null,}) {
  return _then(BreedsPageModel(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<BreedModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [BreedsPageModel].
extension BreedsPageModelPatterns on BreedsPageModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BreedsPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BreedsPageModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BreedsPageModel value)  $default,){
final _that = this;
switch (_that) {
case _BreedsPageModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BreedsPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _BreedsPageModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'current_page')  int currentPage, @JsonKey(name: 'last_page')  int lastPage,  int total,  List<BreedModel> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BreedsPageModel() when $default != null:
return $default(_that.currentPage,_that.lastPage,_that.total,_that.data);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'current_page')  int currentPage, @JsonKey(name: 'last_page')  int lastPage,  int total,  List<BreedModel> data)  $default,) {final _that = this;
switch (_that) {
case _BreedsPageModel():
return $default(_that.currentPage,_that.lastPage,_that.total,_that.data);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'current_page')  int currentPage, @JsonKey(name: 'last_page')  int lastPage,  int total,  List<BreedModel> data)?  $default,) {final _that = this;
switch (_that) {
case _BreedsPageModel() when $default != null:
return $default(_that.currentPage,_that.lastPage,_that.total,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BreedsPageModel extends BreedsPageModel {
  const _BreedsPageModel({@JsonKey(name: 'current_page') this.currentPage = 1, @JsonKey(name: 'last_page') this.lastPage = 1, this.total = 0,  List<BreedModel> data = const <BreedModel>[]}): _data = data,super._();
  factory _BreedsPageModel.fromJson(Map<String, dynamic> json) => _$BreedsPageModelFromJson(json);

@override@JsonKey(name: 'current_page') final  int currentPage;
@override@JsonKey(name: 'last_page') final  int lastPage;
@override@JsonKey() final  int total;
 final  List<BreedModel> _data;
@override@JsonKey() List<BreedModel> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of BreedsPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreedsPageModelCopyWith<_BreedsPageModel> get copyWith => __$BreedsPageModelCopyWithImpl<_BreedsPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BreedsPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BreedsPageModel&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,currentPage,lastPage,total,const DeepCollectionEquality().hash(_data));
}

@override
String toString() {
    return 'BreedsPageModel(currentPage: $currentPage, lastPage: $lastPage, total: $total, data: $data)';
}


}

/// @nodoc
abstract mixin class _$BreedsPageModelCopyWith<$Res> implements $BreedsPageModelCopyWith<$Res> {
  factory _$BreedsPageModelCopyWith(_BreedsPageModel value, $Res Function(_BreedsPageModel) _then) = __$BreedsPageModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'current_page') int currentPage,@JsonKey(name: 'last_page') int lastPage, int total, List<BreedModel> data
});




}
/// @nodoc
class __$BreedsPageModelCopyWithImpl<$Res>
    implements _$BreedsPageModelCopyWith<$Res> {
  __$BreedsPageModelCopyWithImpl(this._self, this._then);

  final _BreedsPageModel _self;
  final $Res Function(_BreedsPageModel) _then;

/// Create a copy of BreedsPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? data = null,}) {
  return _then(_BreedsPageModel(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<BreedModel>,
  ));
}


}

// dart format on
