import 'package:get_it/get_it.dart';

abstract class GroupProvider<T> {
  Iterable<T> call();
}

extension GroupProviderExtension on GetIt {
  Iterable<T> getGroup<T extends Object>() => get<GroupProvider<T>>().call();
}
