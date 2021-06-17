class Participant {
  String name;
  int numOfPoints;

  Participant({required this.name, this.numOfPoints = 0});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(name: json['name'], numOfPoints: json['points']);
  }

  Map<String, dynamic> toJson() =>
      {'name': this.name, 'points': this.numOfPoints};

  String toString() {
    return "Participant:{name: $name, points: $numOfPoints}";
  }
}
