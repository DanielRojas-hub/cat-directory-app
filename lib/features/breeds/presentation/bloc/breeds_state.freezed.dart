// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breeds_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BreedsNotice {

 String get message; BreedsNoticeKind get kind; int get id;
/// Create a copy of BreedsNotice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedsNoticeCopyWith<BreedsNotice> get copyWith => _$BreedsNoticeCopyWithImpl<BreedsNotice>(this as BreedsNotice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BreedsNotice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreedsNotice&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.id, _this.id) || other.id == _this.id));
}


@override
int get hashCode {
  final _this = this as BreedsNotice;
  return Object.hash(runtimeType,_this.message,_this.kind,_this.id);
}

@override
String toString() {
  final _this = this as BreedsNotice;
  return 'BreedsNotice(message: ${_this.message}, kind: ${_this.kind}, id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $BreedsNoticeCopyWith<$Res>  {
  factory $BreedsNoticeCopyWith(BreedsNotice value, $Res Function(BreedsNotice) _then) = _$BreedsNoticeCopyWithImpl;
@useResult
$Res call({
 String message, BreedsNoticeKind kind, int id
});




}
/// @nodoc
class _$BreedsNoticeCopyWithImpl<$Res>
    implements $BreedsNoticeCopyWith<$Res> {
  _$BreedsNoticeCopyWithImpl(this._self, this._then);

  final BreedsNotice _self;
  final $Res Function(BreedsNotice) _then;

/// Create a copy of BreedsNotice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? kind = null,Object? id = null,}) {
  return _then(BreedsNotice(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BreedsNoticeKind,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BreedsNotice].
extension BreedsNoticePatterns on BreedsNotice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BreedsNotice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BreedsNotice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BreedsNotice value)  $default,){
final _that = this;
switch (_that) {
case _BreedsNotice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BreedsNotice value)?  $default,){
final _that = this;
switch (_that) {
case _BreedsNotice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  BreedsNoticeKind kind,  int id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BreedsNotice() when $default != null:
return $default(_that.message,_that.kind,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  BreedsNoticeKind kind,  int id)  $default,) {final _that = this;
switch (_that) {
case _BreedsNotice():
return $default(_that.message,_that.kind,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  BreedsNoticeKind kind,  int id)?  $default,) {final _that = this;
switch (_that) {
case _BreedsNotice() when $default != null:
return $default(_that.message,_that.kind,_that.id);case _:
  return null;

}
}

}

/// @nodoc


class _BreedsNotice implements BreedsNotice {
  const _BreedsNotice({required this.message, required this.kind, required this.id});
  

@override final  String message;
@override final  BreedsNoticeKind kind;
@override final  int id;

/// Create a copy of BreedsNotice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreedsNoticeCopyWith<_BreedsNotice> get copyWith => __$BreedsNoticeCopyWithImpl<_BreedsNotice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BreedsNotice&&(identical(other.message, message) || other.message == message)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,kind,id);
}

@override
String toString() {
    return 'BreedsNotice(message: $message, kind: $kind, id: $id)';
}


}

/// @nodoc
abstract mixin class _$BreedsNoticeCopyWith<$Res> implements $BreedsNoticeCopyWith<$Res> {
  factory _$BreedsNoticeCopyWith(_BreedsNotice value, $Res Function(_BreedsNotice) _then) = __$BreedsNoticeCopyWithImpl;
@override @useResult
$Res call({
 String message, BreedsNoticeKind kind, int id
});




}
/// @nodoc
class __$BreedsNoticeCopyWithImpl<$Res>
    implements _$BreedsNoticeCopyWith<$Res> {
  __$BreedsNoticeCopyWithImpl(this._self, this._then);

  final _BreedsNotice _self;
  final $Res Function(_BreedsNotice) _then;

/// Create a copy of BreedsNotice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? kind = null,Object? id = null,}) {
  return _then(_BreedsNotice(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BreedsNoticeKind,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$BreedsState {

 BreedsStatus get status; List<Breed> get breeds; String get searchQuery; int get currentPage; int get lastPage; int get total; bool get isLoadingMore; bool get isRevalidating; bool get isFromCache; bool get isOnline; DateTime? get lastSyncedAt; String? get errorMessage; String? get paginationErrorMessage; BreedsNotice? get notice;
/// Create a copy of BreedsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedsStateCopyWith<BreedsState> get copyWith => _$BreedsStateCopyWithImpl<BreedsState>(this as BreedsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BreedsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreedsState&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.breeds, _this.breeds)&&(identical(other.searchQuery, _this.searchQuery) || other.searchQuery == _this.searchQuery)&&(identical(other.currentPage, _this.currentPage) || other.currentPage == _this.currentPage)&&(identical(other.lastPage, _this.lastPage) || other.lastPage == _this.lastPage)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.isLoadingMore, _this.isLoadingMore) || other.isLoadingMore == _this.isLoadingMore)&&(identical(other.isRevalidating, _this.isRevalidating) || other.isRevalidating == _this.isRevalidating)&&(identical(other.isFromCache, _this.isFromCache) || other.isFromCache == _this.isFromCache)&&(identical(other.isOnline, _this.isOnline) || other.isOnline == _this.isOnline)&&(identical(other.lastSyncedAt, _this.lastSyncedAt) || other.lastSyncedAt == _this.lastSyncedAt)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.paginationErrorMessage, _this.paginationErrorMessage) || other.paginationErrorMessage == _this.paginationErrorMessage)&&(identical(other.notice, _this.notice) || other.notice == _this.notice));
}


@override
int get hashCode {
  final _this = this as BreedsState;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.breeds),_this.searchQuery,_this.currentPage,_this.lastPage,_this.total,_this.isLoadingMore,_this.isRevalidating,_this.isFromCache,_this.isOnline,_this.lastSyncedAt,_this.errorMessage,_this.paginationErrorMessage,_this.notice);
}

@override
String toString() {
  final _this = this as BreedsState;
  return 'BreedsState(status: ${_this.status}, breeds: ${_this.breeds}, searchQuery: ${_this.searchQuery}, currentPage: ${_this.currentPage}, lastPage: ${_this.lastPage}, total: ${_this.total}, isLoadingMore: ${_this.isLoadingMore}, isRevalidating: ${_this.isRevalidating}, isFromCache: ${_this.isFromCache}, isOnline: ${_this.isOnline}, lastSyncedAt: ${_this.lastSyncedAt}, errorMessage: ${_this.errorMessage}, paginationErrorMessage: ${_this.paginationErrorMessage}, notice: ${_this.notice})';
}


}

/// @nodoc
abstract mixin class $BreedsStateCopyWith<$Res>  {
  factory $BreedsStateCopyWith(BreedsState value, $Res Function(BreedsState) _then) = _$BreedsStateCopyWithImpl;
@useResult
$Res call({
 BreedsStatus status, List<Breed> breeds, String searchQuery, int currentPage, int lastPage, int total, bool isLoadingMore, bool isRevalidating, bool isFromCache, bool isOnline, DateTime? lastSyncedAt, String? errorMessage, String? paginationErrorMessage, BreedsNotice? notice
});


$BreedsNoticeCopyWith<$Res>? get notice;

}
/// @nodoc
class _$BreedsStateCopyWithImpl<$Res>
    implements $BreedsStateCopyWith<$Res> {
  _$BreedsStateCopyWithImpl(this._self, this._then);

  final BreedsState _self;
  final $Res Function(BreedsState) _then;

/// Create a copy of BreedsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? breeds = null,Object? searchQuery = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoadingMore = null,Object? isRevalidating = null,Object? isFromCache = null,Object? isOnline = null,Object? lastSyncedAt = freezed,Object? errorMessage = freezed,Object? paginationErrorMessage = freezed,Object? notice = freezed,}) {
  return _then(BreedsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BreedsStatus,breeds: null == breeds ? _self.breeds : breeds // ignore: cast_nullable_to_non_nullable
as List<Breed>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isRevalidating: null == isRevalidating ? _self.isRevalidating : isRevalidating // ignore: cast_nullable_to_non_nullable
as bool,isFromCache: null == isFromCache ? _self.isFromCache : isFromCache // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,paginationErrorMessage: freezed == paginationErrorMessage ? _self.paginationErrorMessage : paginationErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as BreedsNotice?,
  ));
}
/// Create a copy of BreedsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BreedsNoticeCopyWith<$Res>? get notice {
    if (_self.notice == null) {
    return null;
  }

  return $BreedsNoticeCopyWith<$Res>(_self.notice!, (value) {
    return _then(_self.copyWith(notice: value));
  });
}
}


/// Adds pattern-matching-related methods to [BreedsState].
extension BreedsStatePatterns on BreedsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BreedsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BreedsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BreedsState value)  $default,){
final _that = this;
switch (_that) {
case _BreedsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BreedsState value)?  $default,){
final _that = this;
switch (_that) {
case _BreedsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BreedsStatus status,  List<Breed> breeds,  String searchQuery,  int currentPage,  int lastPage,  int total,  bool isLoadingMore,  bool isRevalidating,  bool isFromCache,  bool isOnline,  DateTime? lastSyncedAt,  String? errorMessage,  String? paginationErrorMessage,  BreedsNotice? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BreedsState() when $default != null:
return $default(_that.status,_that.breeds,_that.searchQuery,_that.currentPage,_that.lastPage,_that.total,_that.isLoadingMore,_that.isRevalidating,_that.isFromCache,_that.isOnline,_that.lastSyncedAt,_that.errorMessage,_that.paginationErrorMessage,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BreedsStatus status,  List<Breed> breeds,  String searchQuery,  int currentPage,  int lastPage,  int total,  bool isLoadingMore,  bool isRevalidating,  bool isFromCache,  bool isOnline,  DateTime? lastSyncedAt,  String? errorMessage,  String? paginationErrorMessage,  BreedsNotice? notice)  $default,) {final _that = this;
switch (_that) {
case _BreedsState():
return $default(_that.status,_that.breeds,_that.searchQuery,_that.currentPage,_that.lastPage,_that.total,_that.isLoadingMore,_that.isRevalidating,_that.isFromCache,_that.isOnline,_that.lastSyncedAt,_that.errorMessage,_that.paginationErrorMessage,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BreedsStatus status,  List<Breed> breeds,  String searchQuery,  int currentPage,  int lastPage,  int total,  bool isLoadingMore,  bool isRevalidating,  bool isFromCache,  bool isOnline,  DateTime? lastSyncedAt,  String? errorMessage,  String? paginationErrorMessage,  BreedsNotice? notice)?  $default,) {final _that = this;
switch (_that) {
case _BreedsState() when $default != null:
return $default(_that.status,_that.breeds,_that.searchQuery,_that.currentPage,_that.lastPage,_that.total,_that.isLoadingMore,_that.isRevalidating,_that.isFromCache,_that.isOnline,_that.lastSyncedAt,_that.errorMessage,_that.paginationErrorMessage,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _BreedsState extends BreedsState {
  const _BreedsState({this.status = BreedsStatus.initial,  List<Breed> breeds = const <Breed>[], this.searchQuery = '', this.currentPage = 0, this.lastPage = 1, this.total = 0, this.isLoadingMore = false, this.isRevalidating = false, this.isFromCache = false, this.isOnline = true, this.lastSyncedAt, this.errorMessage, this.paginationErrorMessage, this.notice}): _breeds = breeds,super._();
  

@override@JsonKey() final  BreedsStatus status;
 final  List<Breed> _breeds;
@override@JsonKey() List<Breed> get breeds {
  if (_breeds is EqualUnmodifiableListView) return _breeds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breeds);
}

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int lastPage;
@override@JsonKey() final  int total;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool isRevalidating;
@override@JsonKey() final  bool isFromCache;
@override@JsonKey() final  bool isOnline;
@override final  DateTime? lastSyncedAt;
@override final  String? errorMessage;
@override final  String? paginationErrorMessage;
@override final  BreedsNotice? notice;

/// Create a copy of BreedsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreedsStateCopyWith<_BreedsState> get copyWith => __$BreedsStateCopyWithImpl<_BreedsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BreedsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.breeds, _breeds)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isRevalidating, isRevalidating) || other.isRevalidating == isRevalidating)&&(identical(other.isFromCache, isFromCache) || other.isFromCache == isFromCache)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.paginationErrorMessage, paginationErrorMessage) || other.paginationErrorMessage == paginationErrorMessage)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_breeds),searchQuery,currentPage,lastPage,total,isLoadingMore,isRevalidating,isFromCache,isOnline,lastSyncedAt,errorMessage,paginationErrorMessage,notice);
}

@override
String toString() {
    return 'BreedsState(status: $status, breeds: $breeds, searchQuery: $searchQuery, currentPage: $currentPage, lastPage: $lastPage, total: $total, isLoadingMore: $isLoadingMore, isRevalidating: $isRevalidating, isFromCache: $isFromCache, isOnline: $isOnline, lastSyncedAt: $lastSyncedAt, errorMessage: $errorMessage, paginationErrorMessage: $paginationErrorMessage, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$BreedsStateCopyWith<$Res> implements $BreedsStateCopyWith<$Res> {
  factory _$BreedsStateCopyWith(_BreedsState value, $Res Function(_BreedsState) _then) = __$BreedsStateCopyWithImpl;
@override @useResult
$Res call({
 BreedsStatus status, List<Breed> breeds, String searchQuery, int currentPage, int lastPage, int total, bool isLoadingMore, bool isRevalidating, bool isFromCache, bool isOnline, DateTime? lastSyncedAt, String? errorMessage, String? paginationErrorMessage, BreedsNotice? notice
});


@override $BreedsNoticeCopyWith<$Res>? get notice;

}
/// @nodoc
class __$BreedsStateCopyWithImpl<$Res>
    implements _$BreedsStateCopyWith<$Res> {
  __$BreedsStateCopyWithImpl(this._self, this._then);

  final _BreedsState _self;
  final $Res Function(_BreedsState) _then;

/// Create a copy of BreedsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? breeds = null,Object? searchQuery = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoadingMore = null,Object? isRevalidating = null,Object? isFromCache = null,Object? isOnline = null,Object? lastSyncedAt = freezed,Object? errorMessage = freezed,Object? paginationErrorMessage = freezed,Object? notice = freezed,}) {
  return _then(_BreedsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BreedsStatus,breeds: null == breeds ? _self._breeds : breeds // ignore: cast_nullable_to_non_nullable
as List<Breed>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isRevalidating: null == isRevalidating ? _self.isRevalidating : isRevalidating // ignore: cast_nullable_to_non_nullable
as bool,isFromCache: null == isFromCache ? _self.isFromCache : isFromCache // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,paginationErrorMessage: freezed == paginationErrorMessage ? _self.paginationErrorMessage : paginationErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as BreedsNotice?,
  ));
}

/// Create a copy of BreedsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BreedsNoticeCopyWith<$Res>? get notice {
    if (_self.notice == null) {
    return null;
  }

  return $BreedsNoticeCopyWith<$Res>(_self.notice!, (value) {
    return _then(_self.copyWith(notice: value));
  });
}
}

// dart format on
