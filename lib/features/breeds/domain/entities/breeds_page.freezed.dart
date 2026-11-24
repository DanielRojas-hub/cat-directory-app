// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breeds_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BreedsPage {

 int get currentPage; int get lastPage; int get total; List<Breed> get items;
/// Create a copy of BreedsPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedsPageCopyWith<BreedsPage> get copyWith => _$BreedsPageCopyWithImpl<BreedsPage>(this as BreedsPage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BreedsPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreedsPage&&(identical(other.currentPage, _this.currentPage) || other.currentPage == _this.currentPage)&&(identical(other.lastPage, _this.lastPage) || other.lastPage == _this.lastPage)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.items, _this.items));
}


@override
int get hashCode {
  final _this = this as BreedsPage;
  return Object.hash(runtimeType,_this.currentPage,_this.lastPage,_this.total,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as BreedsPage;
  return 'BreedsPage(currentPage: ${_this.currentPage}, lastPage: ${_this.lastPage}, total: ${_this.total}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $BreedsPageCopyWith<$Res>  {
  factory $BreedsPageCopyWith(BreedsPage value, $Res Function(BreedsPage) _then) = _$BreedsPageCopyWithImpl;
@useResult
$Res call({
 int currentPage, int lastPage, int total, List<Breed> items
});




}
/// @nodoc
class _$BreedsPageCopyWithImpl<$Res>
    implements $BreedsPageCopyWith<$Res> {
  _$BreedsPageCopyWithImpl(this._self, this._then);

  final BreedsPage _self;
  final $Res Function(BreedsPage) _then;

/// Create a copy of BreedsPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? items = null,}) {
  return _then(BreedsPage(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Breed>,
  ));
}

}


/// Adds pattern-matching-related methods to [BreedsPage].
extension BreedsPagePatterns on BreedsPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BreedsPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BreedsPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BreedsPage value)  $default,){
final _that = this;
switch (_that) {
case _BreedsPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BreedsPage value)?  $default,){
final _that = this;
switch (_that) {
case _BreedsPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentPage,  int lastPage,  int total,  List<Breed> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BreedsPage() when $default != null:
return $default(_that.currentPage,_that.lastPage,_that.total,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentPage,  int lastPage,  int total,  List<Breed> items)  $default,) {final _that = this;
switch (_that) {
case _BreedsPage():
return $default(_that.currentPage,_that.lastPage,_that.total,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentPage,  int lastPage,  int total,  List<Breed> items)?  $default,) {final _that = this;
switch (_that) {
case _BreedsPage() when $default != null:
return $default(_that.currentPage,_that.lastPage,_that.total,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _BreedsPage extends BreedsPage {
  const _BreedsPage({required this.currentPage, required this.lastPage, required this.total, required  List<Breed> items}): _items = items,super._();
  

@override final  int currentPage;
@override final  int lastPage;
@override final  int total;
 final  List<Breed> _items;
@override List<Breed> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BreedsPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreedsPageCopyWith<_BreedsPage> get copyWith => __$BreedsPageCopyWithImpl<_BreedsPage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BreedsPage&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.items, _items));
}


@override
int get hashCode {
    return Object.hash(runtimeType,currentPage,lastPage,total,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'BreedsPage(currentPage: $currentPage, lastPage: $lastPage, total: $total, items: $items)';
}


}

/// @nodoc
abstract mixin class _$BreedsPageCopyWith<$Res> implements $BreedsPageCopyWith<$Res> {
  factory _$BreedsPageCopyWith(_BreedsPage value, $Res Function(_BreedsPage) _then) = __$BreedsPageCopyWithImpl;
@override @useResult
$Res call({
 int currentPage, int lastPage, int total, List<Breed> items
});




}
/// @nodoc
class __$BreedsPageCopyWithImpl<$Res>
    implements _$BreedsPageCopyWith<$Res> {
  __$BreedsPageCopyWithImpl(this._self, this._then);

  final _BreedsPage _self;
  final $Res Function(_BreedsPage) _then;

/// Create a copy of BreedsPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? items = null,}) {
  return _then(_BreedsPage(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Breed>,
  ));
}


}

// dart format on
