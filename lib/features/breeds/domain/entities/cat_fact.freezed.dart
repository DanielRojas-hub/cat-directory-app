// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_fact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatFact {

 String get fact; int get length;
/// Create a copy of CatFact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatFactCopyWith<CatFact> get copyWith => _$CatFactCopyWithImpl<CatFact>(this as CatFact, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatFact;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatFact&&(identical(other.fact, _this.fact) || other.fact == _this.fact)&&(identical(other.length, _this.length) || other.length == _this.length));
}


@override
int get hashCode {
  final _this = this as CatFact;
  return Object.hash(runtimeType,_this.fact,_this.length);
}

@override
String toString() {
  final _this = this as CatFact;
  return 'CatFact(fact: ${_this.fact}, length: ${_this.length})';
}


}

/// @nodoc
abstract mixin class $CatFactCopyWith<$Res>  {
  factory $CatFactCopyWith(CatFact value, $Res Function(CatFact) _then) = _$CatFactCopyWithImpl;
@useResult
$Res call({
 String fact, int length
});




}
/// @nodoc
class _$CatFactCopyWithImpl<$Res>
    implements $CatFactCopyWith<$Res> {
  _$CatFactCopyWithImpl(this._self, this._then);

  final CatFact _self;
  final $Res Function(CatFact) _then;

/// Create a copy of CatFact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fact = null,Object? length = null,}) {
  return _then(CatFact(
fact: null == fact ? _self.fact : fact // ignore: cast_nullable_to_non_nullable
as String,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatFact].
extension CatFactPatterns on CatFact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatFact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatFact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatFact value)  $default,){
final _that = this;
switch (_that) {
case _CatFact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatFact value)?  $default,){
final _that = this;
switch (_that) {
case _CatFact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fact,  int length)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatFact() when $default != null:
return $default(_that.fact,_that.length);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fact,  int length)  $default,) {final _that = this;
switch (_that) {
case _CatFact():
return $default(_that.fact,_that.length);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fact,  int length)?  $default,) {final _that = this;
switch (_that) {
case _CatFact() when $default != null:
return $default(_that.fact,_that.length);case _:
  return null;

}
}

}

/// @nodoc


class _CatFact implements CatFact {
  const _CatFact({required this.fact, required this.length});
  

@override final  String fact;
@override final  int length;

/// Create a copy of CatFact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatFactCopyWith<_CatFact> get copyWith => __$CatFactCopyWithImpl<_CatFact>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatFact&&(identical(other.fact, fact) || other.fact == fact)&&(identical(other.length, length) || other.length == length));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fact,length);
}

@override
String toString() {
    return 'CatFact(fact: $fact, length: $length)';
}


}

/// @nodoc
abstract mixin class _$CatFactCopyWith<$Res> implements $CatFactCopyWith<$Res> {
  factory _$CatFactCopyWith(_CatFact value, $Res Function(_CatFact) _then) = __$CatFactCopyWithImpl;
@override @useResult
$Res call({
 String fact, int length
});




}
/// @nodoc
class __$CatFactCopyWithImpl<$Res>
    implements _$CatFactCopyWith<$Res> {
  __$CatFactCopyWithImpl(this._self, this._then);

  final _CatFact _self;
  final $Res Function(_CatFact) _then;

/// Create a copy of CatFact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fact = null,Object? length = null,}) {
  return _then(_CatFact(
fact: null == fact ? _self.fact : fact // ignore: cast_nullable_to_non_nullable
as String,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
