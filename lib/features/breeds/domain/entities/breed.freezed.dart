// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breed.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Breed {

 String get breed; String get country; String get origin; String get coat; String get pattern;
/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedCopyWith<Breed> get copyWith => _$BreedCopyWithImpl<Breed>(this as Breed, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Breed;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Breed&&(identical(other.breed, _this.breed) || other.breed == _this.breed)&&(identical(other.country, _this.country) || other.country == _this.country)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.coat, _this.coat) || other.coat == _this.coat)&&(identical(other.pattern, _this.pattern) || other.pattern == _this.pattern));
}


@override
int get hashCode {
  final _this = this as Breed;
  return Object.hash(runtimeType,_this.breed,_this.country,_this.origin,_this.coat,_this.pattern);
}

@override
String toString() {
  final _this = this as Breed;
  return 'Breed(breed: ${_this.breed}, country: ${_this.country}, origin: ${_this.origin}, coat: ${_this.coat}, pattern: ${_this.pattern})';
}


}

/// @nodoc
abstract mixin class $BreedCopyWith<$Res>  {
  factory $BreedCopyWith(Breed value, $Res Function(Breed) _then) = _$BreedCopyWithImpl;
@useResult
$Res call({
 String breed, String country, String origin, String coat, String pattern
});




}
/// @nodoc
class _$BreedCopyWithImpl<$Res>
    implements $BreedCopyWith<$Res> {
  _$BreedCopyWithImpl(this._self, this._then);

  final Breed _self;
  final $Res Function(Breed) _then;

/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? breed = null,Object? country = null,Object? origin = null,Object? coat = null,Object? pattern = null,}) {
  return _then(Breed(
breed: null == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,coat: null == coat ? _self.coat : coat // ignore: cast_nullable_to_non_nullable
as String,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Breed].
extension BreedPatterns on Breed {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Breed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Breed() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Breed value)  $default,){
final _that = this;
switch (_that) {
case _Breed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Breed value)?  $default,){
final _that = this;
switch (_that) {
case _Breed() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String breed,  String country,  String origin,  String coat,  String pattern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Breed() when $default != null:
return $default(_that.breed,_that.country,_that.origin,_that.coat,_that.pattern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String breed,  String country,  String origin,  String coat,  String pattern)  $default,) {final _that = this;
switch (_that) {
case _Breed():
return $default(_that.breed,_that.country,_that.origin,_that.coat,_that.pattern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String breed,  String country,  String origin,  String coat,  String pattern)?  $default,) {final _that = this;
switch (_that) {
case _Breed() when $default != null:
return $default(_that.breed,_that.country,_that.origin,_that.coat,_that.pattern);case _:
  return null;

}
}

}

/// @nodoc


class _Breed extends Breed {
  const _Breed({required this.breed, required this.country, required this.origin, required this.coat, required this.pattern}): super._();
  

@override final  String breed;
@override final  String country;
@override final  String origin;
@override final  String coat;
@override final  String pattern;

/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreedCopyWith<_Breed> get copyWith => __$BreedCopyWithImpl<_Breed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Breed&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.country, country) || other.country == country)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.coat, coat) || other.coat == coat)&&(identical(other.pattern, pattern) || other.pattern == pattern));
}


@override
int get hashCode {
    return Object.hash(runtimeType,breed,country,origin,coat,pattern);
}

@override
String toString() {
    return 'Breed(breed: $breed, country: $country, origin: $origin, coat: $coat, pattern: $pattern)';
}


}

/// @nodoc
abstract mixin class _$BreedCopyWith<$Res> implements $BreedCopyWith<$Res> {
  factory _$BreedCopyWith(_Breed value, $Res Function(_Breed) _then) = __$BreedCopyWithImpl;
@override @useResult
$Res call({
 String breed, String country, String origin, String coat, String pattern
});




}
/// @nodoc
class __$BreedCopyWithImpl<$Res>
    implements _$BreedCopyWith<$Res> {
  __$BreedCopyWithImpl(this._self, this._then);

  final _Breed _self;
  final $Res Function(_Breed) _then;

/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breed = null,Object? country = null,Object? origin = null,Object? coat = null,Object? pattern = null,}) {
  return _then(_Breed(
breed: null == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,coat: null == coat ? _self.coat : coat // ignore: cast_nullable_to_non_nullable
as String,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
