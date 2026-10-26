class StatsModel {
  const StatsModel(this.count);

  factory StatsModel.fromJson(Map<String, dynamic> json) =>
      StatsModel((json['count'] as num?)?.toInt() ?? 0);

  final int count;
}
