class StatsModel {
  const StatsModel(this.count);

  factory StatsModel.fromJson(Map<String, dynamic> json) =>
      StatsModel(switch (json['count']) {
        final num v => v.toInt(),
        final String v => num.tryParse(v)?.toInt() ?? 0,
        _ => 0,
      });

  final int count;
}
