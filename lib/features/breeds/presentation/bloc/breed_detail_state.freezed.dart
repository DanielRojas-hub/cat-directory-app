// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breed_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BreedDetailState {

 BreedDetailStatus get breedStatus; Breed? get breed; String? get breedErrorMessage; CatFactStatus get factStatus; CatFact? get fact; String? get factErrorMessage;
/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedDetailStateCopyWith<BreedDetailState> get copyWith => _$BreedDetailStateCopyWithImpl<BreedDetailState>(this as BreedDetailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BreedDetailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreedDetailState&&(identical(other.breedStatus, _this.breedStatus) || other.breedStatus == _this.breedStatus)&&(identical(other.breed, _this.breed) || other.breed == _this.breed)&&(identical(other.breedErrorMessage, _this.breedErrorMessage) || other.breedErrorMessage == _this.breedErrorMessage)&&(identical(other.factStatus, _this.factStatus) || other.factStatus == _this.factStatus)&&(identical(other.fact, _this.fact) || other.fact == _this.fact)&&(identical(other.factErrorMessage, _this.factErrorMessage) || other.factErrorMessage == _this.factErrorMessage));
}


@override
int get hashCode {
  final _this = this as BreedDetailState;
  return Object.hash(runtimeType,_this.breedStatus,_this.breed,_this.breedErrorMessage,_this.factStatus,_this.fact,_this.factErrorMessage);
}

@override
String toString() {
  final _this = this as BreedDetailState;
  return 'BreedDetailState(breedStatus: ${_this.breedStatus}, breed: ${_this.breed}, breedErrorMessage: ${_this.breedErrorMessage}, factStatus: ${_this.factStatus}, fact: ${_this.fact}, factErrorMessage: ${_this.factErrorMessage})';
}


}

/// @nodoc
abstract mixin class $BreedDetailStateCopyWith<$Res>  {
  factory $BreedDetailStateCopyWith(BreedDetailState value, $Res Function(BreedDetailState) _then) = _$BreedDetailStateCopyWithImpl;
@useResult
$Res call({
 BreedDetailStatus breedStatus, Breed? breed, String? breedErrorMessage, CatFactStatus factStatus, CatFact? fact, String? factErrorMessage
});


$BreedCopyWith<$Res>? get breed;$CatFactCopyWith<$Res>? get fact;

}
/// @nodoc
class _$BreedDetailStateCopyWithImpl<$Res>
    implements $BreedDetailStateCopyWith<$Res> {
  _$BreedDetailStateCopyWithImpl(this._self, this._then);

  final BreedDetailState _self;
  final $Res Function(BreedDetailState) _then;

/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? breedStatus = null,Object? breed = freezed,Object? breedErrorMessage = freezed,Object? factStatus = null,Object? fact = freezed,Object? factErrorMessage = freezed,}) {
  return _then(BreedDetailState(
breedStatus: null == breedStatus ? _self.breedStatus : breedStatus // ignore: cast_nullable_to_non_nullable
as BreedDetailStatus,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as Breed?,breedErrorMessage: freezed == breedErrorMessage ? _self.breedErrorMessage : breedErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,factStatus: null == factStatus ? _self.factStatus : factStatus // ignore: cast_nullable_to_non_nullable
as CatFactStatus,fact: freezed == fact ? _self.fact : fact // ignore: cast_nullable_to_non_nullable
as CatFact?,factErrorMessage: freezed == factErrorMessage ? _self.factErrorMessage : factErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BreedCopyWith<$Res>? get breed {
    if (_self.breed == null) {
    return null;
  }

  return $BreedCopyWith<$Res>(_self.breed!, (value) {
    return _then(_self.copyWith(breed: value));
  });
}/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFactCopyWith<$Res>? get fact {
    if (_self.fact == null) {
    return null;
  }

  return $CatFactCopyWith<$Res>(_self.fact!, (value) {
    return _then(_self.copyWith(fact: value));
  });
}
}


/// Adds pattern-matching-related methods to [BreedDetailState].
extension BreedDetailStatePatterns on BreedDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BreedDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BreedDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BreedDetailState value)  $default,){
final _that = this;
switch (_that) {
case _BreedDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BreedDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _BreedDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BreedDetailStatus breedStatus,  Breed? breed,  String? breedErrorMessage,  CatFactStatus factStatus,  CatFact? fact,  String? factErrorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BreedDetailState() when $default != null:
return $default(_that.breedStatus,_that.breed,_that.breedErrorMessage,_that.factStatus,_that.fact,_that.factErrorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BreedDetailStatus breedStatus,  Breed? breed,  String? breedErrorMessage,  CatFactStatus factStatus,  CatFact? fact,  String? factErrorMessage)  $default,) {final _that = this;
switch (_that) {
case _BreedDetailState():
return $default(_that.breedStatus,_that.breed,_that.breedErrorMessage,_that.factStatus,_that.fact,_that.factErrorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BreedDetailStatus breedStatus,  Breed? breed,  String? breedErrorMessage,  CatFactStatus factStatus,  CatFact? fact,  String? factErrorMessage)?  $default,) {final _that = this;
switch (_that) {
case _BreedDetailState() when $default != null:
return $default(_that.breedStatus,_that.breed,_that.breedErrorMessage,_that.factStatus,_that.fact,_that.factErrorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _BreedDetailState implements BreedDetailState {
  const _BreedDetailState({this.breedStatus = BreedDetailStatus.initial, this.breed, this.breedErrorMessage, this.factStatus = CatFactStatus.initial, this.fact, this.factErrorMessage});
  

@override@JsonKey() final  BreedDetailStatus breedStatus;
@override final  Breed? breed;
@override final  String? breedErrorMessage;
@override@JsonKey() final  CatFactStatus factStatus;
@override final  CatFact? fact;
@override final  String? factErrorMessage;

/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreedDetailStateCopyWith<_BreedDetailState> get copyWith => __$BreedDetailStateCopyWithImpl<_BreedDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BreedDetailState&&(identical(other.breedStatus, breedStatus) || other.breedStatus == breedStatus)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.breedErrorMessage, breedErrorMessage) || other.breedErrorMessage == breedErrorMessage)&&(identical(other.factStatus, factStatus) || other.factStatus == factStatus)&&(identical(other.fact, fact) || other.fact == fact)&&(identical(other.factErrorMessage, factErrorMessage) || other.factErrorMessage == factErrorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,breedStatus,breed,breedErrorMessage,factStatus,fact,factErrorMessage);
}

@override
String toString() {
    return 'BreedDetailState(breedStatus: $breedStatus, breed: $breed, breedErrorMessage: $breedErrorMessage, factStatus: $factStatus, fact: $fact, factErrorMessage: $factErrorMessage)';
}


}

/// @nodoc
abstract mixin class _$BreedDetailStateCopyWith<$Res> implements $BreedDetailStateCopyWith<$Res> {
  factory _$BreedDetailStateCopyWith(_BreedDetailState value, $Res Function(_BreedDetailState) _then) = __$BreedDetailStateCopyWithImpl;
@override @useResult
$Res call({
 BreedDetailStatus breedStatus, Breed? breed, String? breedErrorMessage, CatFactStatus factStatus, CatFact? fact, String? factErrorMessage
});


@override $BreedCopyWith<$Res>? get breed;@override $CatFactCopyWith<$Res>? get fact;

}
/// @nodoc
class __$BreedDetailStateCopyWithImpl<$Res>
    implements _$BreedDetailStateCopyWith<$Res> {
  __$BreedDetailStateCopyWithImpl(this._self, this._then);

  final _BreedDetailState _self;
  final $Res Function(_BreedDetailState) _then;

/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breedStatus = null,Object? breed = freezed,Object? breedErrorMessage = freezed,Object? factStatus = null,Object? fact = freezed,Object? factErrorMessage = freezed,}) {
  return _then(_BreedDetailState(
breedStatus: null == breedStatus ? _self.breedStatus : breedStatus // ignore: cast_nullable_to_non_nullable
as BreedDetailStatus,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as Breed?,breedErrorMessage: freezed == breedErrorMessage ? _self.breedErrorMessage : breedErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,factStatus: null == factStatus ? _self.factStatus : factStatus // ignore: cast_nullable_to_non_nullable
as CatFactStatus,fact: freezed == fact ? _self.fact : fact // ignore: cast_nullable_to_non_nullable
as CatFact?,factErrorMessage: freezed == factErrorMessage ? _self.factErrorMessage : factErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BreedCopyWith<$Res>? get breed {
    if (_self.breed == null) {
    return null;
  }

  return $BreedCopyWith<$Res>(_self.breed!, (value) {
    return _then(_self.copyWith(breed: value));
  });
}/// Create a copy of BreedDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFactCopyWith<$Res>? get fact {
    if (_self.fact == null) {
    return null;
  }

  return $CatFactCopyWith<$Res>(_self.fact!, (value) {
    return _then(_self.copyWith(fact: value));
  });
}
}

// dart format on
